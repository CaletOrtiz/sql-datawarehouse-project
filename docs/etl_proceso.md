# Proceso ETL — Capa por capa

```mermaid
flowchart LR
    subgraph E1["BRONCE: Extract + Load"]
        A1[Archivos .tbl en sources/tbl] -->|COPY CSV delimitador pipe| A2[bronce.tbl_*]
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
        PP[p_brand y p_container se normalizan]
        PP --> PB[tbl_brand: b_brandkey = ROW_NUMBER]
        PP --> PC[tbl_container: c_containerkey = ROW_NUMBER]
    end
    subgraph ORD["tbl_orders"]
        PO[o_orderpriority]
        PO --> PO2[split_part con guion, 2<br/>HIGH-URGENT a URGENT]
    end
    subgraph SUPP["tbl_supplier"]
        PS[s_address] --> PS2[TRIM]
    end
```

## Checks de calidad (bronce_check.sql)

```mermaid
flowchart TD
    C[Checks de calidad sobre bronce] --> C1[NULLs y duplicados en PKs]
    C --> C2[Espacios en CHAR - TRIM]
    C --> C3[Fechas inválidas]
    C --> C4[shipdate vs orderdate]
    C --> C5[receiptdate vs shipdate]
    C --> C6[FKs inválidas]
    C --> C7[Valores CHAR fuera de catálogo]
    C --> C8[acctbal negativos]
    C --> C9[discount/tax fuera de rango o más de 2 decimales]
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
