# Documentación del Proyecto — SQL Data Warehouse

Proyecto de Data Warehouse local con **DuckDB** sobre el dataset **TPC-H**,
organizado en arquitectura medallion de 3 capas: **bronce → plata → oro**.

## Estructura

```text
data/              # dwh.duckdb (ignorado en git)
docs/              # Documentación: arquitectura, ERD, ETL (este README)
scripts/
  create_database.sh
  init_schemas.sql       # CREATE SCHEMA bronce/plata/oro
  bronce/
    ddl_bronze.sql       # DDL tablas bronce
    load_bronce.sql      # COPY de .tbl a bronce
  plata/
    bronce_check.sql     # Checks de calidad sobre bronce
    ddl_plata.sql        # DDL tablas plata
    etl.sql              # ETL bronce -> plata
  oro/
    ddl_oro.sql          # DDL esquema estrella oro
    etl_oro.sql          # ETL plata -> oro
sources/tbl/             # Archivos .tbl (ignorados en git)
```

## Cómo funciona el proyecto

1. **Fuentes**: archivos `.tbl` de TPC-H en `sources/tbl/` (delimitador `|`, sin header).
2. **Bronce**: ingesta cruda, tablas espejo de los archivos, sin transformaciones.
3. **Checks**: `bronce_check.sql` valida nulls, duplicados, espacios, fechas y FKs.
4. **Plata**: limpieza (TRIM), filtros de nulls, normalización de `brand`/`container`,
   ajuste de tipos (`DECIMAL(3,2)` en discount/tax), estandarización de
   `o_orderpriority` y columna de auditoría `dwh_created_date`.
5. **Oro**: esquema estrella con hechos (`fact_sales`) y dimensiones
   (`dim_date`, `dim_customer`, `dim_product`, `dim_supplier`) listas para BI.

## Cómo se carga el ETL (orden de ejecución)

```bash
duckdb ./data/dwh.duckdb < ./scripts/init_schemas.sql
duckdb ./data/dwh.duckdb < ./scripts/bronce/ddl_bronze.sql
duckdb ./data/dwh.duckdb < ./scripts/bronce/load_bronce.sql
duckdb ./data/dwh.duckdb < ./scripts/plata/bronce_check.sql   # revisión manual
duckdb ./data/dwh.duckdb < ./scripts/plata/ddl_plata.sql
duckdb ./data/dwh.duckdb < ./scripts/plata/etl.sql
duckdb ./data/dwh.duckdb < ./scripts/oro/ddl_oro.sql
duckdb ./data/dwh.duckdb < ./scripts/oro/etl_oro.sql
```

## Documentos disponibles

| Documento | Contenido |
|---|---|
| [arquitectura.md](arquitectura.md) | Diagrama de arquitectura (medallion), flujo y secuencia ETL |
| [erd_bronce.md](erd_bronce.md) | ERD de la capa bronce |
| [erd_plata.md](erd_plata.md) | ERD de la capa plata |
| [erd_oro.md](erd_oro.md) | ERD del esquema estrella (oro) |
| [etl_proceso.md](etl_proceso.md) | Detalle del proceso ETL, checks y comandos |
| [validacion_etl.md](validacion_etl.md) | Ejecución real validada + volumenes + consultas de ejemplo |
