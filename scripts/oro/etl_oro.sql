/*
==============================================
ETL PLATA -> ORO (STAR SCHEMA FACTURA)
==============================================
Extrae de capa plata, transforma a dimensiones y hechos,
y carga el esquema estrella de la capa oro.
Al final verifica la carga.
*/

-- DIM_TIEMPO: calendario del periodo de análisis 1992-1997
CREATE OR REPLACE TABLE oro.dim_tiempo AS
WITH calendario AS (
    SELECT CAST(d AS DATE) AS fecha_completa
    FROM generate_series(
        DATE '1992-01-01',
        DATE '1997-12-31',
        INTERVAL 1 DAY
    ) AS t(d)
)
SELECT
    CAST(strftime(fecha_completa, '%Y%m%d') AS BIGINT) AS tiempo_pk,
    CAST(strftime(fecha_completa, '%Y') AS SMALLINT) AS anio,
    CAST(strftime(fecha_completa, '%m') AS SMALLINT) AS mes,
    CAST(strftime(fecha_completa, '%d') AS SMALLINT) AS dia,
    fecha_completa,
    strftime(fecha_completa, '%B') AS mes_nombre,
    strftime(fecha_completa, '%A') AS dia_semana,
    CAST((CAST(strftime(fecha_completa, '%m') AS INTEGER) - 1) / 3 + 1 AS SMALLINT) AS trimestre,
    'T' || CAST((CAST(strftime(fecha_completa, '%m') AS INTEGER) - 1) / 3 + 1 AS VARCHAR) AS trimestre_nombre,
    CURRENT_TIMESTAMP AS dwh_created_date
FROM calendario;

-- DIM_CLIENTE
INSERT INTO oro.dim_cliente (cliente_pk, nombre_cliente, segmento_mercado, pais_nombre, regio_nombre)
SELECT
    c.c_custkey::BIGINT,
    c.c_name,
    c.c_mktsegment,
    n.n_name,
    r.r_name
FROM plata.tbl_customer c
LEFT JOIN plata.tbl_nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN plata.tbl_region r ON n.n_regionkey = r.r_regionkey;

-- DIM_PRODUCTO (con marca, tipo y nombre del proveedor)
INSERT INTO oro.dim_producto (producto_pk, nombre_producto, fabricante, marca, tipo_producto, nombre_proveedor)
SELECT
    p.p_partkey::BIGINT,
    p.p_name,
    p.p_mfgr,
    b.b_brandname,
    p.p_type,
    sup.supplier_name
FROM plata.tbl_part p
LEFT JOIN plata.tbl_brand b ON p.p_brand = b.b_brandkey
LEFT JOIN (
    SELECT ps.ps_partkey, s.s_name AS supplier_name,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM plata.tbl_partsupp ps
    JOIN plata.tbl_supplier s ON ps.ps_suppkey = s.s_suppkey
) sup ON sup.ps_partkey = p.p_partkey AND sup.rn = 1;

-- FACTURA (tabla de hechos)
INSERT INTO oro.factura (
    factura_pk, fecha_venta, cliente_fk, producto_fk,
    cantidad_de_producto, precio_bruto, porcentaje_descuento,
    porcentaje_impuesto, venta_neta, monto_impuesto
)
SELECT
    ROW_NUMBER() OVER ()::BIGINT AS factura_pk,
    CAST(strftime(o.o_orderdate, '%Y%m%d') AS BIGINT) AS fecha_venta,
    o.o_custkey::BIGINT AS cliente_fk,
    l.l_partkey::BIGINT AS producto_fk,
    CAST(l.l_quantity AS BIGINT) AS cantidad_de_producto,
    l.l_extendedprice AS precio_bruto,
    l.l_discount AS porcentaje_descuento,
    l.l_tax AS porcentaje_impuesto,
    ROUND(l.l_extendedprice * (1 - l.l_discount), 2) AS venta_neta,
    ROUND(l.l_extendedprice * (1 - l.l_discount) * l.l_tax, 2) AS monto_impuesto
FROM plata.tbl_lineitem l
JOIN plata.tbl_orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderdate >= DATE '1992-01-01'
  AND o.o_orderdate < DATE '1998-01-01';

-- VERIFICACIÓN
SELECT 'dim_tiempo' AS tabla, COUNT(*) AS filas FROM oro.dim_tiempo
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM oro.dim_cliente
UNION ALL SELECT 'dim_producto', COUNT(*) FROM oro.dim_producto
UNION ALL SELECT 'factura', COUNT(*) FROM oro.factura;
SELECT (*) FROM oro.dim_tiempo LIMIT 5;