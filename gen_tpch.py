import os
from pathlib import Path

import duckdb


ROOT = Path(__file__).resolve().parent
TABLES = (
    "region",
    "nation",
    "part",
    "supplier",
    "partsupp",
    "customer",
    "orders",
    "lineitem",
)


def main() -> None:
    scale_factor = float(os.environ.get("TPCH_SCALE_FACTOR", "0.01"))
    if scale_factor <= 0:
        raise ValueError("TPCH_SCALE_FACTOR debe ser mayor que cero.")

    output_dir = ROOT / "sources" / "tbl"
    output_dir.mkdir(parents=True, exist_ok=True)

    connection = duckdb.connect()
    try:
        connection.execute("INSTALL tpch")
        connection.execute("LOAD tpch")
        connection.execute(f"CALL dbgen(sf={scale_factor})")

        for table in TABLES:
            output_path = (output_dir / f"{table}.tbl").as_posix().replace("'", "''")
            connection.execute(
                f"COPY (SELECT * FROM {table}) "
                f"TO '{output_path}' (FORMAT CSV, DELIMITER '|', HEADER false)"
            )
            row_count = connection.execute(
                f"SELECT COUNT(*) FROM {table}"
            ).fetchone()[0]
            print(f"{table}: {row_count} filas", flush=True)
    finally:
        connection.close()


if __name__ == "__main__":
    main()
