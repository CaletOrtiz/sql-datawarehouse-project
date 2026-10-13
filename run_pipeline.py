import os
from pathlib import Path
import subprocess
import sys

import duckdb


ROOT = Path(__file__).resolve().parent
BRONZE_LINEITEM_COUNT = "bronze lineitem"
GOLD_FACT_COUNT = "gold facts"
PARQUET_EXPORTS = (
    ("factura", "oro.factura"),
    ("dim_tiempo", "oro.dim_tiempo"),
    ("dim_cliente", "oro.dim_cliente"),
    ("dim_producto", "oro.dim_producto"),
    ("vw_rfv01_ventas_cliente", "oro.vw_rfv01_ventas_cliente"),
    ("vw_rfv02_ventas_geograficas", "oro.vw_rfv02_ventas_geograficas"),
    ("vw_rfv03_ventas_proveedor", "oro.vw_rfv03_ventas_proveedor"),
    ("vw_rfv04_ventas_retrasadas", "oro.vw_rfv04_ventas_retrasadas"),
    ("vw_rfv05_ventas_segmento", "oro.vw_rfv05_ventas_segmento"),
    ("vw_rfv06_ventas_marca_tipo", "oro.vw_rfv06_ventas_marca_tipo"),
    ("vw_rfv07_descuentos_ventas", "oro.vw_rfv07_descuentos_ventas"),
)
SCRIPTS = (
    "scripts/init_schemas.sql",
    "scripts/bronce/ddl_bronze.sql",
    "scripts/bronce/load_bronce.sql",
    "scripts/plata/bronce_check.sql",
    "scripts/plata/ddl_plata.sql",
    "scripts/plata/etl.sql",
    "scripts/oro/ddl_oro.sql",
    "scripts/oro/etl_oro.sql",
    "scripts/oro/views.sql",
)


def execute_script(connection: duckdb.DuckDBPyConnection, relative_path: str) -> None:
    script_path = ROOT / relative_path
    print(f">>> {relative_path}", flush=True)
    connection.execute(script_path.read_text(encoding="utf-8"))


def export_parquet(
    connection: duckdb.DuckDBPyConnection, output_dir: Path
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for file_name, relation in PARQUET_EXPORTS:
        output_path = (output_dir / f"{file_name}.parquet").resolve()
        sql_path = str(output_path).replace("'", "''")
        row_count = connection.execute(
            f"SELECT COUNT(*) FROM {relation}"
        ).fetchone()[0]
        connection.execute(
            f"COPY (SELECT * FROM {relation}) TO '{sql_path}' "
            "(FORMAT PARQUET, COMPRESSION SNAPPY, OVERWRITE_OR_IGNORE TRUE)"
        )
        exported_rows = connection.execute(
            "SELECT COALESCE(SUM(num_rows), 0) FROM parquet_file_metadata(?)",
            [str(output_path)],
        ).fetchone()[0]
        if exported_rows != row_count:
            raise RuntimeError(
                f"Exportación Parquet incompleta para {file_name}: "
                f"se esperaban {row_count} filas y se exportaron {exported_rows}."
            )
        print(
            f"Parquet {output_path.name}: {exported_rows} filas "
            f"({output_path.stat().st_size:,} bytes)",
            flush=True,
        )


def validate_warehouse(connection: duckdb.DuckDBPyConnection) -> None:
    expected_calendar_days = 2192
    checks = {
        BRONZE_LINEITEM_COUNT: "SELECT COUNT(*) FROM bronce.tbl_lineitem",
        "silver lineitem": "SELECT COUNT(*) FROM plata.tbl_lineitem",
        GOLD_FACT_COUNT: "SELECT COUNT(*) FROM oro.factura",
        "calendar days": "SELECT COUNT(*) FROM oro.dim_tiempo",
        "customer dimension": "SELECT COUNT(*) FROM oro.dim_cliente",
        "product dimension": "SELECT COUNT(*) FROM oro.dim_producto",
        "gold views": """
            SELECT COUNT(*)
            FROM duckdb_views()
            WHERE schema_name = 'oro' AND view_name LIKE 'vw_rfv%'
        """,
    }
    counts = {
        label: connection.execute(query).fetchone()[0]
        for label, query in checks.items()
    }

    if counts[BRONZE_LINEITEM_COUNT] == 0:
        raise RuntimeError("La capa bronce no contiene líneas de venta.")
    if counts["silver lineitem"] != counts[BRONZE_LINEITEM_COUNT]:
        raise RuntimeError("La carga de lineitem entre bronce y plata está incompleta.")
    for label in (GOLD_FACT_COUNT, "customer dimension", "product dimension"):
        if counts[label] == 0:
            raise RuntimeError(f"La validación falló: {label} está vacía.")
    if counts["calendar days"] != expected_calendar_days:
        raise RuntimeError(
            f"El calendario debe tener {expected_calendar_days} días; "
            f"se encontraron {counts['calendar days']}."
        )
    if counts["gold views"] != 7:
        raise RuntimeError(f"Se esperaban 7 vistas oro; se encontraron {counts['gold views']}.")
    expected_facts = connection.execute(
        """
        SELECT COUNT(*)
        FROM plata.tbl_lineitem l
        JOIN plata.tbl_orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderdate >= DATE '1992-01-01'
          AND o.o_orderdate < DATE '1998-01-01'
        """
    ).fetchone()[0]
    if counts[GOLD_FACT_COUNT] != expected_facts:
        raise RuntimeError(
            f"Se esperaban {expected_facts} hechos; "
            f"se encontraron {counts[GOLD_FACT_COUNT]}."
        )

    orphan_checks = {
        "fecha": """
            SELECT COUNT(*) FROM oro.factura f
            LEFT JOIN oro.dim_tiempo d ON f.fecha_venta = d.tiempo_pk
            WHERE d.tiempo_pk IS NULL
        """,
        "cliente": """
            SELECT COUNT(*) FROM oro.factura f
            LEFT JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
            WHERE c.cliente_pk IS NULL
        """,
        "producto": """
            SELECT COUNT(*) FROM oro.factura f
            LEFT JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
            WHERE p.producto_pk IS NULL
        """,
        "proveedor": """
            SELECT COUNT(*) FROM oro.factura f
            LEFT JOIN plata.tbl_supplier s ON f.proveedor_fk = s.s_suppkey
            WHERE s.s_suppkey IS NULL
        """,
    }
    for dimension, query in orphan_checks.items():
        orphan_count = connection.execute(query).fetchone()[0]
        if orphan_count:
            raise RuntimeError(
                f"Se encontraron {orphan_count} hechos sin dimensión de {dimension}."
            )

    view_names = connection.execute(
        """
        SELECT view_name
        FROM duckdb_views()
        WHERE schema_name = 'oro' AND view_name LIKE 'vw_rfv%'
        """
    ).fetchall()
    for (view_name,) in view_names:
        connection.execute(f'SELECT * FROM oro."{view_name}" LIMIT 1').fetchall()

    print("Validación correcta:")
    for label, count in counts.items():
        print(f"  {label}: {count}")


def main() -> None:
    database_path = Path(os.environ.get("DWH_PATH", "data/dwh.duckdb"))
    if not database_path.is_absolute():
        database_path = ROOT / database_path
    database_path.parent.mkdir(parents=True, exist_ok=True)
    parquet_dir = Path(os.environ.get("PARQUET_OUTPUT_DIR", "data/parquet"))
    if not parquet_dir.is_absolute():
        parquet_dir = ROOT / parquet_dir

    scale_factor = os.environ.get("TPCH_SCALE_FACTOR", "0.01")
    print(f"Generando TPC-H con factor de escala {scale_factor}.", flush=True)
    subprocess.run([sys.executable, str(ROOT / "gen_tpch.py")], check=True, cwd=ROOT)

    connection = duckdb.connect(str(database_path))
    try:
        for script in SCRIPTS:
            execute_script(connection, script)
        validate_warehouse(connection)
        export_parquet(connection, parquet_dir)
    finally:
        connection.close()

    print(f"Warehouse creado en {database_path}.", flush=True)


if __name__ == "__main__":
    main()
