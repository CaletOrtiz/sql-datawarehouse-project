/*
==============================================
ETL PLATA -> ORO (STAR SCHEMA FACTURA) · v2 (sin proveedor)
==============================================
Extrae de capa plata, transforma a dimensiones y hechos,
y carga el esquema estrella de la capa oro.
Ejecutar siempre despues de ddl_oro_v2.sql (las cargas son INSERT, no idempotentes).
Al final verifica la carga.
*/

-- DIM_TIEMPO: calendario del periodo de análisis 1992-1997
-- INSERT para conservar la PK y los tipos definidos en el DDL.
INSERT INTO oro.dim_tiempo (tiempo_pk, anio, mes, dia, fecha_completa, mes_nombre,
                            dia_semana, trimestre, trimestre_nombre)
WITH calendario AS (
    SELECT CAST(d AS DATE) AS fecha_completa
    FROM generate_series(DATE '1992-01-01', DATE '1997-12-31', INTERVAL 1 DAY) AS t(d)
)
SELECT
    CAST(strftime(fecha_completa, '%Y%m%d') AS BIGINT),
    CAST(year(fecha_completa)  AS SMALLINT),
    CAST(month(fecha_completa) AS SMALLINT),
    CAST(day(fecha_completa)   AS SMALLINT),
    fecha_completa,
    ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto',
     'Septiembre','Octubre','Noviembre','Diciembre'][month(fecha_completa)],
    ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'][isodow(fecha_completa)],
    CAST((month(fecha_completa) - 1) // 3 + 1 AS SMALLINT),
    'Trimestre ' || CAST((month(fecha_completa) - 1) // 3 + 1 AS VARCHAR)
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

-- DIM_PRODUCTO
INSERT INTO oro.dim_producto (producto_pk, nombre_producto, fabricante, marca, tipo_producto)
SELECT
    p.p_partkey::BIGINT,
    p.p_name,
    p.p_mfgr,
    COALESCE(b.b_brandname, 'Sin marca'),
    p.p_type
FROM plata.tbl_part p
LEFT JOIN plata.tbl_brand b ON p.p_brand = b.b_brandkey;

-- FACTURA (tabla de hechos)
INSERT INTO oro.factura (
    factura_pk, numero_orden, numero_linea,
    fecha_venta, cliente_fk, producto_fk,
    cantidad_de_producto, precio_bruto, porcentaje_descuento,
    porcentaje_impuesto, venta_neta, monto_impuesto
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY l.l_orderkey, l.l_linenumber
    )::BIGINT AS factura_pk,
    l.l_orderkey::BIGINT AS numero_orden,
    l.l_linenumber::BIGINT AS numero_linea,
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

-- VERIFICACION DE CARGA (todas deben cumplirse)
SELECT
    (SELECT COUNT(*) FROM oro.dim_tiempo)  AS dias_calendario,           -- 2192
    (SELECT COUNT(*) FROM oro.factura)     AS lineas_factura,
    (SELECT COUNT(*) FROM plata.tbl_lineitem l JOIN plata.tbl_orders o ON l.l_orderkey = o.o_orderkey
      WHERE o.o_orderdate >= DATE '1992-01-01' AND o.o_orderdate < DATE '1998-01-01') AS lineas_esperadas,
    (SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
      WHERE t.tiempo_pk IS NULL)           AS huerfanas_tiempo,           -- 0
    (SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
      WHERE c.cliente_pk IS NULL)          AS huerfanas_cliente,          -- 0
    (SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
      WHERE p.producto_pk IS NULL)         AS huerfanas_producto;         -- 0

-- VENTA NETA POR REGION Y NACION DEL CLIENTE
SELECT
    c.regio_nombre AS region,
    c.pais_nombre AS nacion,
    ROUND(SUM(f.venta_neta), 2) AS venta_neta_total
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
GROUP BY c.regio_nombre, c.pais_nombre
ORDER BY venta_neta_total DESC, region, nacion;

-- TOP 10 PRODUCTOS POR VENTA NETA EN 1997
SELECT
    COALESCE(p.marca, 'Sin marca') AS marca,
    f.producto_fk AS producto_pk,
    p.nombre_producto,
    SUM(f.cantidad_de_producto) AS unidades_vendidas,
    ROUND(SUM(f.venta_neta), 2) AS venta_neta_total
FROM oro.factura f
JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
WHERE t.anio = 1997
GROUP BY p.marca, f.producto_fk, p.nombre_producto
ORDER BY venta_neta_total DESC, unidades_vendidas DESC, p.nombre_producto
LIMIT 10;