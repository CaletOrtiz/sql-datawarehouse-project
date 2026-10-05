# Modelo de Datos — Capa ORO (Esquema Estrella)

```mermaid
erDiagram
    DIM_TIEMPO ||--o{ FACTURA : "fecha_venta"
    DIM_CLIENTE ||--o{ FACTURA : "cliente_fk"
    DIM_PRODUCTO ||--o{ FACTURA : "producto_fk"

    FACTURA {
        bigint factura_pk PK
        bigint fecha_venta FK
        bigint cliente_fk FK
        bigint producto_fk FK
        bigint cantidad_de_producto
        decimal precio_bruto
        decimal porcentaje_descuento
        decimal porcentaje_impuesto
        decimal venta_neta
        decimal monto_impuesto
        timestamp dwh_created_date
    }
    DIM_TIEMPO {
        bigint tiempo_pk PK
        smallint anio
        smallint mes
        smallint dia
        date fecha_completa
        varchar mes_nombre
        varchar dia_semana
        smallint trimestre
        varchar trimestre_nombre
        timestamp dwh_created_date
    }
    DIM_CLIENTE {
        bigint cliente_pk PK
        varchar nombre_cliente
        varchar segmento_mercado
        varchar pais_nombre
        varchar regio_nombre
        timestamp dwh_created_date
    }
    DIM_PRODUCTO {
        bigint producto_pk PK
        varchar nombre_producto
        varchar fabricante
        varchar marca
        varchar tipo_producto
        timestamp dwh_created_date
    }
```

## Cómo armarlo

| Entidad | Origen en plata | Transformaciones |
|---|---|---|
| `dim_tiempo` | periodo de análisis | calendario 1992-01-01 a 1997-12-31 con `generate_series`, atributos de fecha (año, mes, día, trimestre) |
| `dim_cliente` | `tbl_customer` + `tbl_nation` + `tbl_region` | aplanado de país y región |
| `dim_producto` | `tbl_part` + `tbl_brand` | denormalización de marca |
| `factura` | `tbl_lineitem` JOIN `tbl_orders` | Pedidos con fecha entre 1992-01-01 y 1997-12-31; incluye líneas devueltas y no devueltas. `venta_neta = precio_bruto * (1 - descuento)`, `monto_impuesto = venta_neta * impuesto` |
