-- =============================================================================
-- CAPA ORO · VISTAS DE VENTAS (DuckDB · TPC-H dbgen)  ·  v4
-- Alcance: solo VENTAS / FACTURAS. Fuera de este datamart: RF-V03 (proveedor),
-- RF-V04 (ventas retrasadas), RF-V09 (modo de transporte) y RF-V11 (empaque).
-- Proveedor/compras y logística de despacho serían otros datamarts.
-- Grano: 1 fila de oro.factura = 1 línea de factura; 1 factura = 1 numero_orden.
-- Esquema en estrella: oro.factura + oro.dim_tiempo / dim_cliente / dim_producto
--
-- Supuestos (verificar contra tu ETL, que no estaba en los archivos subidos):
--   * oro.factura = 1 fila por línea de pedido (numero_orden, numero_linea)
--   * venta_neta     = precio_bruto * (1 - porcentaje_descuento)      (sin impuesto)
--   * monto_impuesto = venta_neta * porcentaje_impuesto  (confirmado en etl_oro.sql)
--   * monto de descuento = precio_bruto - venta_neta (cuadra exacto con el redondeo por línea)
--   * producto_fk = p_partkey ; fecha_venta = fecha del pedido
--   * Todas las vistas leen ÚNICAMENTE de oro (ninguna depende de plata).
-- =============================================================================


-- =============================================================================
-- RF-V01: Ventas por cliente
-- Cambio: la vista base trae TODOS los clientes con ranking y % de participación
-- (Power BI filtra el Top N y los totales no quedan truncados por el LIMIT).
-- vw_rfv01_top100_clientes conserva el requisito original "Top 100".
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv01_ventas_cliente AS
WITH base AS (
    SELECT
        c.cliente_pk,
        c.nombre_cliente,
        c.segmento_mercado,
        c.pais_nombre,
        c.regio_nombre AS region,
        COUNT(DISTINCT f.numero_orden) AS total_facturas,
        SUM(f.venta_neta)              AS total_venta_neta,
        SUM(f.cantidad_de_producto)    AS total_unidades,
        ROUND(SUM(f.venta_neta) / NULLIF(COUNT(DISTINCT f.numero_orden), 0), 2) AS ticket_medio
    FROM oro.factura f
    JOIN oro.dim_cliente c ON f.cliente_fk = c.cliente_pk
    GROUP BY c.cliente_pk, c.nombre_cliente, c.segmento_mercado, c.pais_nombre, c.regio_nombre
)
SELECT
    *,
    RANK() OVER (ORDER BY total_venta_neta DESC) AS ranking_venta,
    ROUND(100.0 * total_venta_neta / SUM(total_venta_neta) OVER (), 4) AS pct_participacion
FROM base;

CREATE OR REPLACE VIEW oro.vw_rfv01_top100_clientes AS
SELECT *
FROM oro.vw_rfv01_ventas_cliente
WHERE ranking_venta <= 100
ORDER BY ranking_venta;


-- =============================================================================
-- RF-V02: Ventas geográficas (sin cambios de lógica; se añade mes-agnóstico + unidades)
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv02_ventas_geograficas AS
SELECT
    c.regio_nombre AS region,
    c.pais_nombre  AS pais,
    t.anio,
    COUNT(DISTINCT f.numero_orden) AS total_facturas,
    SUM(f.cantidad_de_producto)    AS total_unidades,
    SUM(f.precio_bruto)            AS total_venta_bruta,
    SUM(f.venta_neta)              AS total_venta_neta,
    SUM(f.monto_impuesto)          AS total_impuesto
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk  = c.cliente_pk
JOIN oro.dim_tiempo  t ON f.fecha_venta = t.tiempo_pk
GROUP BY c.regio_nombre, c.pais_nombre, t.anio
ORDER BY region ASC, total_venta_neta DESC;


-- =============================================================================
-- RF-V05: Ventas por segmento (+ participación anual y crecimiento interanual)
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv05_ventas_segmento AS
SELECT
    c.segmento_mercado,
    t.anio,
    COUNT(DISTINCT f.numero_orden) AS total_facturas,
    SUM(f.cantidad_de_producto)    AS unidades_vendidas,
    SUM(f.precio_bruto)            AS venta_bruta_total,
    SUM(f.venta_neta)              AS venta_neta_total,
    ROUND(100.0 * SUM(f.venta_neta) / SUM(SUM(f.venta_neta)) OVER (PARTITION BY t.anio), 2)
        AS pct_participacion_anio,
    ROUND(100.0 * (SUM(f.venta_neta)
        / NULLIF(LAG(SUM(f.venta_neta)) OVER (PARTITION BY c.segmento_mercado ORDER BY t.anio), 0) - 1), 2)
        AS crecimiento_interanual_pct
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk  = c.cliente_pk
JOIN oro.dim_tiempo  t ON f.fecha_venta = t.tiempo_pk
GROUP BY c.segmento_mercado, t.anio
ORDER BY t.anio ASC, venta_neta_total DESC;


-- =============================================================================
-- RF-V06: Ventas por fabricante, marca y tipo (+ participación sobre el total)
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv06_ventas_marca_tipo AS
SELECT
    p.fabricante,
    p.marca,
    p.tipo_producto,
    t.anio,
    SUM(f.cantidad_de_producto) AS unidades_vendidas,
    SUM(f.precio_bruto)         AS total_venta_bruta,
    SUM(f.venta_neta)           AS total_venta_neta,
    ROUND(100.0 * SUM(f.venta_neta) / SUM(SUM(f.venta_neta)) OVER (PARTITION BY t.anio), 4)
        AS pct_participacion_anio
FROM oro.factura f
JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk
JOIN oro.dim_tiempo   t ON f.fecha_venta = t.tiempo_pk
GROUP BY p.fabricante, p.marca, p.tipo_producto, t.anio
ORDER BY total_venta_neta DESC;


-- =============================================================================
-- RF-V07: Descuentos sobre ventas
-- Cambio: se incluye t.mes en el SELECT (ordenar meses en Power BI) y unidades.
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv07_descuentos_ventas AS
SELECT
    t.anio,
    t.mes,
    t.mes_nombre,
    c.segmento_mercado,
    SUM(f.precio_bruto)                          AS venta_bruta_total,
    SUM(f.precio_bruto - f.venta_neta) AS monto_descuento_total,
    SUM(f.venta_neta)                            AS venta_neta_total,
    ROUND(100.0 * SUM(f.precio_bruto - f.venta_neta)
          / NULLIF(SUM(f.precio_bruto), 0), 2)   AS pct_descuento_efectivo
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk  = c.cliente_pk
JOIN oro.dim_tiempo  t ON f.fecha_venta = t.tiempo_pk
GROUP BY t.anio, t.mes, t.mes_nombre, c.segmento_mercado
ORDER BY t.anio ASC, t.mes ASC;


-- =============================================================================
-- RF-V08: IVA de ventas — impuesto sobre venta neta por nación y mes
-- Nación = nación del CLIENTE (donde se factura el impuesto).
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv08_iva_ventas AS
SELECT
    t.anio,
    t.mes,
    t.mes_nombre,
    c.regio_nombre AS region,
    c.pais_nombre  AS pais,
    SUM(f.venta_neta)     AS total_venta_neta,
    SUM(f.monto_impuesto) AS total_impuesto,
    ROUND(100.0 * SUM(f.monto_impuesto) / NULLIF(SUM(f.venta_neta), 0), 2) AS pct_impuesto_efectivo,
    SUM(f.venta_neta + f.monto_impuesto) AS total_venta_con_impuesto
FROM oro.factura f
JOIN oro.dim_cliente c ON f.cliente_fk  = c.cliente_pk
JOIN oro.dim_tiempo  t ON f.fecha_venta = t.tiempo_pk
GROUP BY t.anio, t.mes, t.mes_nombre, c.regio_nombre, c.pais_nombre
ORDER BY t.anio, t.mes, total_impuesto DESC;


-- =============================================================================
-- RF-V10: Estacionalidad 1992-1997 — serie de 72 meses por año, trimestre y mes
-- indice_estacionalidad: 100 = promedio mensual del año; >100 = mes por encima.
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv10_estacionalidad AS
WITH mensual AS (
    SELECT
        t.anio,
        t.trimestre,
        t.trimestre_nombre,
        t.mes,
        t.mes_nombre,
        make_date(CAST(t.anio AS INTEGER), CAST(t.mes AS INTEGER), 1) AS periodo,
        COUNT(DISTINCT f.numero_orden) AS total_facturas,
        SUM(f.cantidad_de_producto)    AS unidades_vendidas,
        SUM(f.precio_bruto)            AS venta_bruta_total,
        SUM(f.venta_neta)              AS venta_neta_total
    FROM oro.factura f
    JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
    WHERE t.anio BETWEEN 1992 AND 1997
    GROUP BY t.anio, t.trimestre, t.trimestre_nombre, t.mes, t.mes_nombre
)
SELECT
    *,
    ROUND(100.0 * venta_neta_total / AVG(venta_neta_total) OVER (PARTITION BY anio), 2)
        AS indice_estacionalidad,
    ROUND(100.0 * (venta_neta_total / NULLIF(LAG(venta_neta_total, 1)  OVER (ORDER BY periodo), 0) - 1), 2)
        AS var_mensual_pct,
    ROUND(100.0 * (venta_neta_total / NULLIF(LAG(venta_neta_total, 12) OVER (ORDER BY periodo), 0) - 1), 2)
        AS var_interanual_pct,
    ROUND(AVG(venta_neta_total) OVER (ORDER BY periodo ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)
        AS media_movil_3m
FROM mensual
ORDER BY periodo;


-- =============================================================================
-- RF-V12: Dashboard ejecutivo — KPIs anuales integrados (V01..V11)
-- Una fila por año. Los totales globales y los distintos (clientes, pedidos)
-- deben calcularse como medidas DAX sobre factura, no sumando esta vista.
-- =============================================================================
CREATE OR REPLACE VIEW oro.vw_rfv12_kpis_ejecutivo AS
WITH anual AS (
    SELECT
        t.anio,
        COUNT(DISTINCT f.numero_orden)  AS total_facturas,
        COUNT(*)                        AS total_lineas,
        COUNT(DISTINCT f.cliente_fk)    AS clientes_activos,
        SUM(f.cantidad_de_producto)     AS unidades_vendidas,
        SUM(f.precio_bruto)             AS venta_bruta,
        SUM(f.precio_bruto - f.venta_neta) AS monto_descuento,
        SUM(f.venta_neta)               AS venta_neta,
        SUM(f.monto_impuesto)           AS impuesto
    FROM oro.factura f
    JOIN oro.dim_tiempo t ON f.fecha_venta = t.tiempo_pk
    GROUP BY t.anio
)
SELECT
    anio,
    total_facturas,
    total_lineas,
    clientes_activos,
    unidades_vendidas,
    venta_bruta,
    monto_descuento,
    venta_neta,
    impuesto,
    ROUND(venta_neta / NULLIF(total_facturas, 0), 2)                  AS ticket_medio,
    ROUND(venta_neta / NULLIF(clientes_activos, 0), 2)               AS venta_por_cliente,
    ROUND(100.0 * monto_descuento / NULLIF(venta_bruta, 0), 2)       AS pct_descuento_efectivo,
    ROUND(100.0 * impuesto / NULLIF(venta_neta, 0), 2)               AS pct_impuesto_efectivo,
    LAG(venta_neta) OVER (ORDER BY anio)                              AS venta_neta_anio_anterior,
    ROUND(100.0 * (venta_neta / NULLIF(LAG(venta_neta) OVER (ORDER BY anio), 0) - 1), 2)
                                                                       AS crecimiento_interanual_pct
FROM anual
ORDER BY anio;


-- =============================================================================
-- VALIDACIONES (ejecutar tras crear las vistas; todas deben dar lo esperado)
-- =============================================================================
-- 1) Misma venta neta total en todas las vistas aditivas (diferencia = 0)
-- SELECT
--   (SELECT SUM(venta_neta) FROM oro.factura)                              AS factura,
--   (SELECT SUM(total_venta_neta) FROM oro.vw_rfv01_ventas_cliente)        AS v01,
--   (SELECT SUM(total_venta_neta) FROM oro.vw_rfv02_ventas_geograficas)    AS v02,
--   (SELECT SUM(venta_neta_total) FROM oro.vw_rfv05_ventas_segmento)       AS v05,
--   (SELECT SUM(total_venta_neta) FROM oro.vw_rfv06_ventas_marca_tipo)     AS v06,
--   (SELECT SUM(venta_neta_total) FROM oro.vw_rfv07_descuentos_ventas)     AS v07,
--   (SELECT SUM(total_venta_neta) FROM oro.vw_rfv08_iva_ventas)            AS v08,
--   (SELECT SUM(venta_neta)       FROM oro.vw_rfv12_kpis_ejecutivo)        AS v12;
--
-- 2) Fórmula de venta neta e impuesto (el ETL redondea por línea: esperar diferencias
--    de centavos a pocas unidades sobre millones de filas, no exactamente 0)
-- SELECT SUM(venta_neta) - SUM(precio_bruto * (1 - porcentaje_descuento))        AS dif_neta,
--        SUM(monto_impuesto) - SUM(venta_neta * porcentaje_impuesto)             AS dif_impuesto
-- FROM oro.factura;
--
-- 3) Cardinalidades esperadas
-- SELECT COUNT(*) FROM oro.vw_rfv10_estacionalidad;                -- 72
-- SELECT COUNT(DISTINCT segmento_mercado) FROM oro.vw_rfv05_ventas_segmento; -- 5
--
-- 4) Integridad referencial de la factura (todas deben dar 0)
-- SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_cliente  c ON f.cliente_fk  = c.cliente_pk  WHERE c.cliente_pk  IS NULL;
-- SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_producto p ON f.producto_fk = p.producto_pk WHERE p.producto_pk IS NULL;
-- SELECT COUNT(*) FROM oro.factura f LEFT JOIN oro.dim_tiempo   t ON f.fecha_venta = t.tiempo_pk   WHERE t.tiempo_pk   IS NULL;


-- =============================================================================
-- NOTA DE MODELO: oro.factura ya no necesita proveedor_fk (sin dim_proveedor).
-- DuckDB limita ALTER sobre tablas con PK/UNIQUE: recrear factura desde ddl_oro.sql
-- sin la columna proveedor_fk y quitarla del ETL de carga.
-- =============================================================================