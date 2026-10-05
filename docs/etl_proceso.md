# Proceso ETL — Capa por capa

```mermaid
flowchart LR
    subgraph E1["BRONCE: Extract + Load"]
        A1[Archivos .tbl<br/>sources/tbl] -->|COPY CSV '|'| A2[bronce.tbl_*]
    end

    subgraph E2["PLATA: Transform + Load"]
        B1[bronce_check.sql<br/>checks de calidad] --> B2[etl.sql<br/>TRIM, filtros NULL,<br/>normalización brand/container,<br/>SPLIT_PART orden, fechas válidas]
        B2 --> B3[plata.tbl_*]
    end

    subgraph E3["ORO: Modelar + Load"]
        C1[etl_oro.sql<br/>dims + fact_sales<br/>revenue calculado] --> C2[oro.*<br/>star schema]
    end

    E1 --> E2 --> E3
```

## Detalle por tabla (plata)

```mermaid
flowchart TD
    subgraph PART["tbl_part"]
        PP[p_brand / p_container → catálogos]
        PP --> PB[tbl_brand: b_brandkey = ROW_NUMBER]
        PP --> PC[tbl_container: c_containerkey = ROW_NUMBER]
    end
    subgraph ORD["tbl_orders"]
        PO[o_orderpriority]
        PO --> PO2[split_part '-', 2<br/>'HIGH-URGENT' → 'URGENT']
    end
    subgraph SUPP["tbl_supplier"]
        PS[s_address] --> PS2[TRIM]
    end
```

## Checks de calidad (bronce_check.sql)

```mermaid
mindmap
  root((Checks))
    NULLs y duplicados en PKs
    Espacios en CHAR (TRIM)
    Fechas inválidas
    shipdate vs orderdate
    receiptdate vs shipdate
    FKs inválidas
    Valores CHAR fuera de catálogo
    acctbal negativos
    discount/tax fuera de rango o > 2 decimales
```

## Comandos para ejecutar todo

```bash
# 1. Crear base y esquemas
duckdb ./data/dwh.duckdb < ./scripts/init_schemas.sql

# 2. Bronce
duckdb ./data/dwh.duckdb < ./scripts/bronce/ddl_bronze.sql
duckdb ./data/dwh.duckdb < ./scripts/bronce/load_bronce.sql

# 3. Checks de calidad
duckdb ./data/dwh.duckdb < ./scripts/plata/bronce_check.sql

# 4. Plata
duckdb ./data/dwh.duckdb < ./scripts/plata/ddl_plata.sql
duckdb ./data/dwh.duckdb < ./scripts/plata/etl.sql

# 5. Oro
duckdb ./data/dwh.duckdb < ./scripts/oro/ddl_oro.sql
duckdb ./data/dwh.duckdb < ./scripts/oro/etl_oro.sql
```
