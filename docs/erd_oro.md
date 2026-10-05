# Modelo de Datos — Capa ORO (Esquema Estrella)

```mermaid
erDiagram
    DIM_DATE ||--o{ FACT_SALES : "order_date_key / ship_date_key / commit_date_key / receipt_date_key"
    DIM_CUSTOMER ||--o{ FACT_SALES : "customer_key"
    DIM_PRODUCT ||--o{ FACT_SALES : "product_key"
    DIM_SUPPLIER ||--o{ FACT_SALES : "supplier_key"

    FACT_SALES {
        int sales_key PK
        int order_id
        int line_number
        int customer_key FK
        int product_key FK
        int supplier_key FK
        int order_date_key FK
        int ship_date_key FK
        int commit_date_key FK
        int receipt_date_key FK
        decimal quantity
        decimal extended_price
        decimal discount
        decimal tax
        decimal revenue
        char order_status
        varchar order_priority
        char return_flag
        char line_status
        char ship_mode
        char ship_instruct
        timestamp dwh_created_date
    }
    DIM_DATE {
        int date_key PK
        date full_date
        int year
        int quarter
        int month
        varchar month_name
        int day
        varchar day_name
        boolean is_weekend
    }
    DIM_CUSTOMER {
        int customer_key PK
        varchar customer_name
        varchar address
        char phone
        char market_segment
        varchar nation
        varchar region
        decimal account_balance
        timestamp dwh_created_date
    }
    DIM_PRODUCT {
        int product_key PK
        varchar product_name
        char manufacturer
        varchar brand
        varchar type
        int size
        varchar container
        decimal retail_price
        timestamp dwh_created_date
    }
    DIM_SUPPLIER {
        int supplier_key PK
        char supplier_name
        varchar address
        char phone
        varchar nation
        varchar region
        decimal account_balance
        timestamp dwh_created_date
    }
```

## Cómo armarlo

| Entidad | Origen en plata | Transformaciones |
|---|---|---|
| `dim_date` | fechas de `tbl_orders` y `tbl_lineitem` | calendario con `generate_series`, atributos de fecha (año, mes, día, fin de semana) |
| `dim_customer` | `tbl_customer` + `tbl_nation` + `tbl_region` | aplanado de nación y región, denormalización |
| `dim_product` | `tbl_part` + `tbl_brand` + `tbl_container` | denormalización de marca y contenedor |
| `dim_supplier` | `tbl_supplier` + `tbl_nation` + `tbl_region` | aplanado de nación y región |
| `fact_sales` | `tbl_lineitem` JOIN `tbl_orders` | métricas: `revenue = extended_price * (1 - discount) * (1 + tax)` |
