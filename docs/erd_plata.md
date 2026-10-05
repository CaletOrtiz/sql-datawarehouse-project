# Modelo de Datos — Capa PLATA

Misma estructura que bronce + limpieza (TRIM, tipos DECIMAL(3,2) en discount/tax,
normalización de marca y contenedor en tablas catálogo) y columna de auditoría
`dwh_created_date`.

```mermaid
erDiagram
    REGION ||--o{ NATION : "r_regionkey"
    NATION ||--o{ CUSTOMER : "n_nationkey"
    NATION ||--o{ SUPPLIER : "n_nationkey"
    CUSTOMER ||--o{ ORDERS : "c_custkey"
    ORDERS ||--o{ LINEITEM : "o_orderkey"
    PART ||--o{ PARTSUPP : "p_partkey"
    SUPPLIER ||--o{ PARTSUPP : "s_suppkey"
    PART ||--o{ LINEITEM : "p_partkey"
    SUPPLIER ||--o{ LINEITEM : "s_suppkey"
    BRAND ||--o{ PART : "b_brandkey = p_brand"
    CONTAINER ||--o{ PART : "c_containerkey = p_container"

    REGION {
        int r_regionkey
        varchar r_name
        varchar r_comment
        timestamp dwh_created_date
    }
    NATION {
        int n_nationkey
        varchar n_name
        int n_regionkey
        varchar n_comment
        timestamp dwh_created_date
    }
    BRAND {
        int b_brandkey
        varchar b_brandname
        timestamp dwh_created_date
    }
    CONTAINER {
        int c_containerkey
        varchar c_container
        timestamp dwh_created_date
    }
    PART {
        int p_partkey
        varchar p_name
        char p_mfgr
        int p_brand FK
        varchar p_type
        int p_size
        int p_container FK
        decimal p_retailprice
        varchar p_comment
        timestamp dwh_created_date
    }
    SUPPLIER {
        int s_suppkey
        char s_name
        varchar s_address
        int s_nationkey
        char s_phone
        decimal s_acctbal
        varchar s_comment
        timestamp dwh_created_date
    }
    PARTSUPP {
        int ps_partkey
        int ps_suppkey
        int ps_availqty
        decimal ps_supplycost
        varchar ps_comment
        timestamp dwh_created_date
    }
    CUSTOMER {
        int c_custkey
        varchar c_name
        varchar c_address
        int c_nationkey
        char c_phone
        decimal c_acctbal
        char c_mktsegment
        varchar c_comment
        timestamp dwh_created_date
    }
    ORDERS {
        int o_orderkey
        int o_custkey
        char o_orderstatus
        decimal o_totalprice
        date o_orderdate
        varchar o_orderpriority
        char o_clerk
        int o_shippriority
        varchar o_comment
        timestamp dwh_created_date
    }
    LINEITEM {
        int l_orderkey
        int l_partkey
        int l_suppkey
        int l_linenumber
        decimal l_quantity
        decimal l_extendedprice
        decimal l_discount
        decimal l_tax
        char l_returnflag
        char l_linestatus
        date l_shipdate
        date l_commitdate
        date l_receiptdate
        char l_shipinstruct
        char l_shipmode
        varchar l_comment
        timestamp dwh_created_date
    }
```
