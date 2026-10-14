# Validación del Proceso ETL (ejecución real)

Proceso ejecutado con éxito sobre datos TPC-H de prueba (SF=0.01) el 5/10/2026
usando DuckDB 1.5.6 y los scripts del repositorio.

## Pipeline validado

```mermaid
flowchart LR
    A[gen_tpch.py<br/>sources/tbl/*.tbl] --> B[init_schemas.sql]
    B --> C[bronce/ddl_bronze.sql]
    C --> D[bronce/load_bronce.sql<br/>60175 lineitem]
    D --> E[plata/ddl_plata.sql]
    E --> F[plata/etl.sql<br/>10 tablas]
    F --> G[oro/ddl_oro.sql]
    G --> H[oro/etl_oro.sql<br/>4 tablas del esquema estrella]
    H --> I[oro/views.sql<br/>9 vistas]
    I --> J[(data/dwh.duckdb)]
```

## Volúmenes cargados

```mermaid
flowchart LR
    V1[region: 5] --- V2[nation: 25] --- V3[supplier: 100] --- V4[brand: 25] --- V5[container: 40] --- V6[part: 2000] --- V7[partsupp: 8000] --- V8[customer: 1500] --- V9[orders: 15000] --- V10[lineitem: 60175]
```

| Capa | Tabla | Filas |
|---|---|---|
| bronce/plata | tbl_region | 5 |
| | tbl_nation | 25 |
| | tbl_supplier | 100 |
| | tbl_brand | 25 |
| | tbl_container | 40 |
| | tbl_part | 2000 |
| | tbl_partsupp | 8000 |
| | tbl_customer / dim_cliente | 1500 |
| | tbl_orders | 15000 |
| | tbl_lineitem | 60175 |
| oro | factura | Líneas (devueltas y no devueltas) de pedidos con fecha entre 1992-01-01 y 1997-12-31 |
| | dim_tiempo | 2192 (1992-01-01 → 1997-12-31) |

## Consultas de ejemplo sobre ORO

```sql
-- 1. Revenue por año y quarter
SELECT d.anio, d.trimestre,
       ROUND(SUM(f.venta_neta), 2) AS venta_neta
FROM oro.factura f
JOIN oro.dim_tiempo d ON f.fecha_venta = d.tiempo_pk
GROUP BY 1, 2 ORDER BY 1, 2;

-- 2. Top 10 clientes por venta neta
SELECT c.nombre_cliente, c.pais_nombre,
       ROUND(SUM(f.venta_neta), 2) AS venta_neta
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
GROUP BY 1, 2 ORDER BY venta_neta DESC LIMIT 10;

-- 3. Venta neta por marca
SELECT p.marca, ROUND(SUM(f.venta_neta), 2) AS venta_neta
FROM oro.factura f
JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
GROUP BY 1 ORDER BY venta_neta DESC;

-- 4. KPIs ejecutivos por año
SELECT anio, total_facturas, clientes_activos, venta_neta,
       crecimiento_interanual_pct
FROM oro.vw_rfv12_kpis_ejecutivo
ORDER BY anio;
```

## Buenas prácticas de ejecución

```mermaid
flowchart TD
    R[Re-ejecutar ETL completo] --> S{Existe data/dwh.duckdb?}
    S -->|Sí| DEL[Borrar archivo o usar CREATE OR REPLACE]
    S -->|No| RUN
    DEL --> RUN[duckdb data/dwh.duckdb < script.sql]
    RUN --> V[Verificar conteos con duckdb_tables()]
```
