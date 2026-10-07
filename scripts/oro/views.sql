-- =============================================================================
-- RF-V01: Ventas por cliente
-- Descripción: Top 100 clientes por venta neta, cantidad de pedidos y ticket medio
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv01_ventas_cliente AS
SELECT 
    c.cliente_pk,
    c.nombre_cliente,
    c.segmento_mercado,
    c.pais_nombre,
    COUNT(DISTINCT f.factura_pk) AS total_pedidos,
    SUM(f.venta_neta) AS total_venta_neta,
    SUM(f.cantidad_de_producto) AS total_unidades,
    -- Ticket medio por pedido del cliente
    ROUND(SUM(f.venta_neta) / NULLIF(COUNT(DISTINCT f.factura_pk), 0), 2) AS ticket_medio
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
GROUP BY 
    c.cliente_pk,
    c.nombre_cliente,
    c.segmento_mercado,
    c.pais_nombre
ORDER BY total_venta_neta DESC
LIMIT 100;

-- =============================================================================
-- RF-V02: Ventas geográficas
-- Descripción: Venta neta consolidada por región y nación (país)
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv02_ventas_geograficas AS
SELECT 
    c.regio_nombre AS region,
    c.pais_nombre AS pais,
    t.anio,
    COUNT(DISTINCT f.factura_pk) AS total_facturas,
    SUM(f.precio_bruto) AS total_venta_bruta,
    SUM(f.venta_neta) AS total_venta_neta,
    SUM(f.monto_impuesto) AS total_impuesto
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
GROUP BY 
    c.regio_nombre,
    c.pais_nombre,
    t.anio
ORDER BY 
    region ASC, 
    total_venta_neta DESC;

-- =============================================================================
-- RF-V03: Ventas por proveedor
-- Descripción: Ranking de proveedores por venta neta
-- (Relaciona la línea de detalle desde Plata con la tabla de Hechos)
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv03_ventas_proveedor AS
SELECT 
    s.s_suppkey AS proveedor_pk,
    s.s_name AS proveedor_nombre,
    n.n_name AS proveedor_pais,
    r.r_name AS proveedor_region,
    COUNT(DISTINCT f.factura_pk) AS total_lineas_vendidas,
    SUM(f.cantidad_de_producto) AS total_unidades_suministradas,
    SUM(f.venta_neta) AS total_venta_neta
FROM oro.factura f
JOIN plata.tbl_lineitem l 
    ON f.factura_pk = l.l_orderkey 
   AND f.producto_fk = l.l_partkey
JOIN plata.tbl_supplier s 
    ON l.l_suppkey = s.s_suppkey
JOIN plata.tbl_nation n 
    ON s.s_nationkey = n.n_nationkey
JOIN plata.tbl_region r 
    ON n.n_regionkey = r.r_regionkey
GROUP BY 
    s.s_suppkey,
    s.s_name,
    n.n_name,
    r.r_name
ORDER BY total_venta_neta DESC;

-- =============================================================================
-- RF-V04: Ventas retrasadas
-- Descripción: Líneas de orden con despacho posterior a la fecha comprometida
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv04_ventas_retrasadas AS
SELECT 
    t.anio,
    t.mes_nombre,
    c.nombre_cliente,
    p.nombre_producto,
    l.l_orderkey AS numero_orden,
    l.l_shipdate AS fecha_despacho,
    l.l_commitdate AS fecha_comprometida,
    -- Cálculo de días de retraso en DuckDB
    DATEDIFF('day', l.l_commitdate, l.l_shipdate) AS dias_de_retraso,
    f.cantidad_de_producto,
    f.venta_neta AS venta_neta_afectada
FROM plata.tbl_lineitem l
JOIN oro.factura f 
    ON l.l_orderkey = f.factura_pk 
   AND l.l_partkey = f.producto_fk
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
WHERE l.l_shipdate > l.l_commitdate;

-- =============================================================================
-- RF-V05: Ventas por segmento
-- Descripción: Comparativo de los 5 segmentos de mercado con serie anual
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv05_ventas_segmento AS
SELECT 
    c.segmento_mercado,
    t.anio,
    COUNT(DISTINCT f.factura_pk) AS total_pedidos,
    SUM(f.cantidad_de_producto) AS unidades_vendidas,
    SUM(f.precio_bruto) AS venta_bruta_total,
    SUM(f.venta_neta) AS venta_neta_total
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
GROUP BY 
    c.segmento_mercado,
    t.anio
ORDER BY 
    t.anio ASC, 
    venta_neta_total DESC;

-- =============================================================================
-- RF-V06: Ventas por marca y tipo
-- Descripción: Análisis de ventas según Fabricante, Marca y Tipo de producto
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv06_ventas_marca_tipo AS
SELECT 
    p.fabricante,
    p.marca,
    p.tipo_producto,
    t.anio,
    SUM(f.cantidad_de_producto) AS unidades_vendidas,
    SUM(f.precio_bruto) AS total_venta_bruta,
    SUM(f.venta_neta) AS total_venta_neta
FROM oro.factura f
JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
GROUP BY 
    p.fabricante,
    p.marca,
    p.tipo_producto,
    t.anio
ORDER BY 
    total_venta_neta DESC;

-- =============================================================================
-- RF-V07: Descuentos sobre ventas
-- Descripción: Análisis del Porcentaje y Monto Descontado sobre la Venta Bruta
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv07_descuentos_ventas AS
SELECT 
    t.anio,
    t.mes_nombre,
    c.segmento_mercado,
    SUM(f.precio_bruto) AS venta_bruta_total,
    SUM(f.precio_bruto * f.porcentaje_descuento) AS monto_descuento_total,
    SUM(f.venta_neta) AS venta_neta_total,
    -- Porcentaje efectivo global descontado sobre la venta bruta
    ROUND(
        (SUM(f.precio_bruto * f.porcentaje_descuento) / NULLIF(SUM(f.precio_bruto), 0)) * 100, 
        2
    ) AS pct_descuento_efectivo
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
GROUP BY 
    t.anio,
    t.mes_nombre,
    t.mes,
    c.segmento_mercado
ORDER BY 
    t.anio ASC, 
    t.mes ASC;


SELECT * FROM oro.vw_rfv01_ventas_cliente LIMIT 5;