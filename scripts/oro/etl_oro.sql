/*
==============================================
ETL PLATA -> ORO (STAR SCHEMA)
==============================================
Extrae de capa plata, transforma a dimensiones y hechos,
y carga el esquema estrella de la capa oro.
Al final verifica la carga.
*/

-- DIM_DATE: calendario generado a partir del rango de fechas del negocio
CREATE OR REPLACE TABLE oro.dim_date AS
WITH fechas AS (
    SELECT o_orderdate AS d FROM plata.tbl_orders
    UNION
    SELECT l_shipdate FROM plata.tbl_lineitem
    UNION
    SELECT l_commitdate FROM plata.tbl_lineitem
    UNION
    SELECT l_receiptdate FROM plata.tbl_lineitem
),
rango AS (
    SELECT MIN(d) AS ini, MAX(d) AS fin FROM fechas
),
calendario AS (
    SELECT CAST(generate_series(ini, fin, INTERVAL 1 DAY) AS DATE) AS full_date
    FROM rango
)
SELECT
    CAST(strftime(full_date, '%Y%m%d') AS INTEGER) AS date_key,
    full_date,
    CAST(strftime(full_date, '%Y') AS INTEGER) AS year,
    (CAST(strftime(full_date, '%m') AS INTEGER) - 1) / 3 + 1 AS quarter,
    CAST(strftime(full_date, '%m') AS INTEGER) AS month,
    strftime(full_date, '%B') AS month_name,
    CAST(strftime(full_date, '%d') AS INTEGER) AS day,
    strftime(full_date, '%A') AS day_name,
    CAST(strftime(full_date, '%w') AS INTEGER) IN (0, 6) AS is_weekend
FROM calendario;

-- DIM_CUSTOMER
INSERT INTO oro.dim_customer (customer_key, customer_id, customer_name, address, phone, market_segment, nation, region, account_balance)
SELECT
    c.c_custkey,
    c.c_custkey,
    c.c_name,
    c.c_address,
    c.c_phone,
    c.c_mktsegment,
    n.n_name,
    r.r_name,
    c.c_acctbal
FROM plata.tbl_customer c
LEFT JOIN plata.tbl_nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN plata.tbl_region r ON n.n_regionkey = r.r_regionkey;

-- DIM_PRODUCT (normalizada con brand y container)
INSERT INTO oro.dim_product (product_key, product_id, product_name, manufacturer, brand, type, size, container, retail_price)
SELECT
    p.p_partkey,
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    b.b_brandname,
    p.p_type,
    p.p_size,
    con.c_container::VARCHAR AS container,
    p.p_retailprice
FROM plata.tbl_part p
LEFT JOIN plata.tbl_brand b ON p.p_brand = b.b_brandkey
LEFT JOIN plata.tbl_container con ON p.p_container = con.c_containerkey;

-- DIM_SUPPLIER
INSERT INTO oro.dim_supplier (supplier_key, supplier_id, supplier_name, address, phone, nation, region, account_balance)
SELECT
    s.s_suppkey,
    s.s_suppkey,
    s.s_name,
    s.s_address,
    s.s_phone,
    n.n_name,
    r.r_name,
    s.s_acctbal
FROM plata.tbl_supplier s
LEFT JOIN plata.tbl_nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN plata.tbl_region r ON n.n_regionkey = r.r_regionkey;

-- FACT_SALES
INSERT INTO oro.fact_sales (
    sales_key, order_id, line_number, customer_key, product_key, supplier_key,
    order_date_key, ship_date_key, commit_date_key, receipt_date_key,
    quantity, extended_price, discount, tax, revenue,
    order_status, order_priority, return_flag, line_status, ship_mode, ship_instruct
)
SELECT
    ROW_NUMBER() OVER () AS sales_key,
    o.o_orderkey,
    l.l_linenumber,
    o.o_custkey,
    l.l_partkey,
    l.l_suppkey,
    CAST(strftime(o.o_orderdate, '%Y%m%d') AS INTEGER),
    CAST(strftime(l.l_shipdate, '%Y%m%d') AS INTEGER),
    CAST(strftime(l.l_commitdate, '%Y%m%d') AS INTEGER),
    CAST(strftime(l.l_receiptdate, '%Y%m%d') AS INTEGER),
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    ROUND(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax), 2),
    o.o_orderstatus,
    o.o_orderpriority,
    l.l_returnflag,
    l.l_linestatus,
    l.l_shipmode,
    l.l_shipinstruct
FROM plata.tbl_lineitem l
JOIN plata.tbl_orders o ON l.l_orderkey = o.o_orderkey;

-- VERIFICACIÓN
SELECT 'dim_date' AS tabla, COUNT(*) AS filas FROM oro.dim_date
UNION ALL SELECT 'dim_customer', COUNT(*) FROM oro.dim_customer
UNION ALL SELECT 'dim_product', COUNT(*) FROM oro.dim_product
UNION ALL SELECT 'dim_supplier', COUNT(*) FROM oro.dim_supplier
UNION ALL SELECT 'fact_sales', COUNT(*) FROM oro.fact_sales;
