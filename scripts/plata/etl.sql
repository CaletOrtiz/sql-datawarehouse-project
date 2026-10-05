-- Este ETL transforma y carga datos desde el esquema bronce al esquema plata,
-- limpiando y relacionando algunos valores; al final verifica las tablas cargadas.


CREATE OR REPLACE TABLE plata.tbl_brand AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY TRIM(p_brand)) AS b_brandkey,
    TRIM(p_brand) AS b_brandname,
    CURRENT_TIMESTAMP AS dwh_created_date
FROM (
    SELECT DISTINCT p_brand 
    FROM bronce.tbl_part 
    WHERE p_brand IS NOT NULL
);

CREATE OR REPLACE TABLE plata.tbl_container AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY TRIM(p_container)) AS c_containerkey,
    TRIM(p_container) AS c_container,
    CURRENT_TIMESTAMP AS dwh_created_date
FROM (
    SELECT DISTINCT p_container 
    FROM bronce.tbl_part 
    WHERE p_container IS NOT NULL
);

INSERT INTO plata.tbl_part (
    p_partkey,
    p_name,
    p_mfgr,
    p_brand,
    p_type,
    p_size,
    p_container,
    p_retailprice,
    p_comment
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    b.b_brandkey,
    p.p_type,
    p.p_size,
    c.c_containerkey,
    p.p_retailprice,
    p.p_comment
FROM bronce.tbl_part p
LEFT JOIN plata.tbl_brand b 
    ON TRIM(p.p_brand) = b.b_brandname
LEFT JOIN plata.tbl_container c 
    ON TRIM(p.p_container) = c.c_container;


-- CARGA DE DATOS EN LA TABLA PLATA.TBL_PARTSUPP
INSERT INTO plata.tbl_partsupp (
    ps_partkey,
    ps_suppkey,
    ps_availqty,
    ps_supplycost,
    ps_comment
)
SELECT 
    ps.ps_partkey,
    ps.ps_suppkey,
    ps.ps_availqty,
    ps.ps_supplycost,
    ps.ps_comment
FROM bronce.tbl_partsupp ps
WHERE ps.ps_partkey IS NOT NULL AND ps.ps_suppkey IS NOT NULL;

--Carga de datos en la tabla PLATA.TBL_CUSTOMER
INSERT INTO plata.tbl_customer (
    c_custkey,
    c_name,
    c_address,
    c_nationkey,
    c_phone,
    c_acctbal,
    c_mktsegment,
    c_comment
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_address,
    c.c_nationkey,
    c.c_phone,
    c.c_acctbal,
    c.c_mktsegment,
    c.c_comment
FROM bronce.tbl_customer c
WHERE c.c_custkey IS NOT NULL;

--Carga de datos en la tabla PLATA.TBL_SUPPLIER
INSERT INTO plata.tbl_supplier (
    s_suppkey,
    s_name,
    s_address,
    s_nationkey,
    s_phone,
    s_acctbal,
    s_comment
)
SELECT 
    s.s_suppkey,
    s.s_name,
    TRIM(s.s_address) AS s_address,
    s.s_nationkey,
    s.s_phone,
    s.s_acctbal,
    s.s_comment
FROM bronce.tbl_supplier s
WHERE s.s_suppkey IS NOT NULL;

---Carga de datos en la tabla PLATA.TBL_REGION
INSERT INTO plata.tbl_region (
    r_regionkey,
    r_name,
    r_comment
)
SELECT 
    r.r_regionkey,
    r.r_name,
    r.r_comment
FROM bronce.tbl_region r
WHERE r.r_regionkey IS NOT NULL;

--Carga de datos en la tabla PLATA.TBL_NATION
INSERT INTO plata.tbl_nation (
    n_nationkey,
    n_name,
    n_regionkey,
    n_comment
)
SELECT 
    n.n_nationkey,
    n.n_name,
    n.n_regionkey,
    n.n_comment
FROM bronce.tbl_nation n
WHERE n.n_nationkey IS NOT NULL;

--Carga de datos en la tabla PLATA.TBL_ORDERS
INSERT INTO plata.tbl_orders (
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority,
    o_clerk,
    o_shippriority,
    o_comment
)
SELECT 
    o.o_orderkey,
    o.o_custkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    SPLIT_PART(TRIM(o_orderpriority), '-', 2) AS o_orderpriority,
    o.o_clerk,
    o.o_shippriority,
    o.o_comment
FROM bronce.tbl_orders o
WHERE o.o_orderkey IS NOT NULL AND o.o_custkey IS NOT NULL;

--cargar datos en la tabla PLATA.TBL_LINEITEM
INSERT INTO plata.tbl_lineitem (
    l_orderkey,
    l_partkey,
    l_suppkey,
    l_linenumber,
    l_quantity,
    l_extendedprice,
    l_discount,
    l_tax,
    l_returnflag,
    l_linestatus,
    l_shipdate,
    l_commitdate,
    l_receiptdate,
    l_shipinstruct,
    l_shipmode,
    l_comment
)
SELECT 
    l.l_orderkey,
    l.l_partkey,
    l.l_suppkey,
    l.l_linenumber,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    l.l_returnflag,
    l.l_linestatus,
    l.l_shipdate,
    l.l_commitdate,
    l.l_receiptdate,
    l.l_shipinstruct,
    l.l_shipmode,
    l.l_comment
FROM bronce.tbl_lineitem l
WHERE l.l_orderkey IS NOT NULL AND l.l_partkey IS NOT NULL AND l.l_suppkey IS NOT NULL;


SELECT 'tbl_region' AS tabla, COUNT(*) AS total_filas FROM plata.tbl_region
UNION ALL
SELECT 'tbl_nation', COUNT(*) FROM plata.tbl_nation
UNION ALL
SELECT 'tbl_brand', COUNT(*) FROM plata.tbl_brand
UNION ALL
SELECT 'tbl_container', COUNT(*) FROM plata.tbl_container
UNION ALL
SELECT 'tbl_part', COUNT(*) FROM plata.tbl_part
UNION ALL
SELECT 'tbl_supplier', COUNT(*) FROM plata.tbl_supplier
UNION ALL
SELECT 'tbl_partsupp', COUNT(*) FROM plata.tbl_partsupp
UNION ALL
SELECT 'tbl_customer', COUNT(*) FROM plata.tbl_customer
UNION ALL
SELECT 'tbl_orders', COUNT(*) FROM plata.tbl_orders
UNION ALL
SELECT 'tbl_lineitem', COUNT(*) FROM plata.tbl_lineitem;


SELECT 
    schema_name AS esquema,
    table_name AS tabla,
    estimated_size AS filas_estimadas,
    column_count AS num_columnas
FROM duckdb_tables()
WHERE schema_name = 'plata'
ORDER BY estimated_size DESC;