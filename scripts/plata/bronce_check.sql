/*
ANALISIS DE ISSUES ANTES DE ALMACENAR EN LA CAPA PLATA

CHECKS
    -NULLOS O DUPLICADOS EN LLAVES PRIMARIAS
    -ESPACIOS NO DESEADOS EN CAMPOS CHAR
    -FECHAS INVALIDAS
    -CONSISTENCIA DE DATOS ENTRE TABLAS
    -FOREIGN KEYS INVALIDAS
    -VALORES INVALIDOS EN CAMPOS DE TIPO CHAR
*/

--CHECK NULLS AND DUPLICATES IN PRIMARY KEYS
SELECT c_custkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_customer
GROUP BY c_custkey
HAVING COUNT(*) > 1 OR c_custkey IS NULL;

SELECT o_orderkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_orders
GROUP BY o_orderkey
HAVING COUNT(*) > 1 OR o_orderkey IS NULL;

SELECT l_orderkey, l_linenumber, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_lineitem
GROUP BY l_orderkey, l_linenumber
HAVING COUNT(*) > 1 OR l_orderkey IS NULL OR l_linenumber IS NULL;

SELECT p_partkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_part
GROUP BY p_partkey
HAVING COUNT(*) > 1 OR p_partkey IS NULL;

SELECT s_suppkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_supplier
GROUP BY s_suppkey
HAVING COUNT(*)>1 OR s_suppkey IS NULL;

SELECT ps_partkey, ps_suppkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_partsupp
GROUP BY ps_partkey, ps_suppkey
HAVING COUNT(*)>1 OR ps_partkey IS NULL OR ps_suppkey IS NULL

SELECT r_regionkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_region
GROUP BY r_regionkey
HAVING COUNT(*)>1 OR r_regionkey IS NULL;

select n_nationkey, COUNT(*) AS DUPLICADOS
FROM bronce.tbl_nation
GROUP BY n_nationkey
HAVING COUNT(*)>1 OR n_nationkey IS NULL;

--CHECK UNWANTED SPACES IN CHAR FIELDS
SELECT c_name FROM bronce.tbl_customer
WHERE c_name != TRIM(c_name);

SELECT c_address FROM bronce.tbl_customer
WHERE c_address != TRIM(c_address);

Select c_phone FROM bronce.tbl_customer
WHERE c_phone != TRIM(c_phone);

SELECT s_name FROM bronce.tbl_supplier
WHERE s_name != TRIM(s_name);

SELECT s_address FROM bronce.tbl_supplier
WHERE s_address != TRIM(s_address);

SELECT s_phone FROM bronce.tbl_supplier
WHERE s_phone != TRIM(s_phone);

select p_mfgr FROM bronce.tbl_part
WHERE p_mfgr != TRIM(p_mfgr);

SELECT p_brand FROM bronce.tbl_part
WHERE p_brand != TRIM(p_brand);

SELECT p_type FROM bronce.tbl_part
WHERE p_type != TRIM(p_type);

SELECT p_container FROM bronce.tbl_part
WHERE p_container != TRIM(p_container);

SELECT o_orderstatus FROM bronce.tbl_orders
WHERE o_orderstatus != TRIM(o_orderstatus);

SELECT o_orderpriority FROM bronce.tbl_orders
WHERE o_orderpriority != TRIM(o_orderpriority);

SELECT o_clerk FROM bronce.tbl_orders
WHERE o_clerk != TRIM(o_clerk);

SELECT l_shipinstruct FROM bronce.tbl_lineitem
WHERE l_shipinstruct != TRIM(l_shipinstruct);

SELECT l_shipmode FROM bronce.tbl_lineitem
WHERE l_shipmode != TRIM(l_shipmode);


SELECT c_mktsegment FROM bronce.tbl_customer WHERE c_mktsegment != TRIM(c_mktsegment);
SELECT l_returnflag FROM bronce.tbl_lineitem WHERE l_returnflag != TRIM(l_returnflag);
SELECT l_linestatus FROM bronce.tbl_lineitem WHERE l_linestatus != TRIM(l_linestatus);

-- CHECK FOR INVALID DATES
SELECT o_orderdate
FROM bronce.tbl_orders
WHERE o_orderdate < '1992-01-01' OR o_orderdate > '1998-12-31';

SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_orders o
JOIN bronce.tbl_lineitem l 
ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate < o.o_orderdate;

SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_lineitem
WHERE l_shipdate > l_receiptdate;

--CHECK CONCISTENCIA DE DATOS ENTRE TABLAS
SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_orders o
LEFT JOIN bronce.tbl_customer c
ON o.o_custkey = c.c_custkey
WHERE c.c_custkey IS NULL;

--CHECK FOR INVALID FOREIGN KEYS
SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_lineitem l
LEFT JOIN bronce.tbl_orders o
ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderkey IS NULL;

SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_lineitem l
LEFT JOIN bronce.tbl_part p
ON l.l_partkey = p.p_partkey
WHERE p.p_partkey IS NULL;

SELECT COUNT(*) AS total_invalidados
FROM bronce.tbl_lineitem l
LEFT JOIN bronce.tbl_supplier s
ON l.l_suppkey = s.s_suppkey
WHERE s.s_suppkey IS NULL;

SELECT DISTINCT p_container
FROM bronce.tbl_part;

SELECT DISTINCT p_brand, COUNT(*) AS total
FROM bronce.tbl_part
GROUP BY p_brand
ORDER BY total DESC;

SELECT DISTINCT p_type, COUNT(*) AS total
FROM bronce.tbl_part
GROUP BY p_type
ORDER BY total DESC;

SELECT DISTINCT c_mktsegment, COUNT(*) AS total
FROM bronce.tbl_customer
GROUP BY c_mktsegment
ORDER BY total DESC;

SELECT DISTINCT l_returnflag FROM bronce.tbl_lineitem;
SELECT DISTINCT l_shipinstruct, COUNT(*) AS veces FROM bronce.tbl_lineitem
GROUP BY l_shipinstruct
ORDER BY veces DESC;
SELECT DISTINCT p_container FROM bronce.tbl_part;

SELECT c_acctbal FROM bronce.tbl_customer
WHERE c_acctbal < 0;

SELECT DISTINCT o_orderpriority FROM bronce.tbl_orders;

SELECT 
    COUNT(*) FILTER (WHERE ROUND(l_discount, 2) != l_discount) AS discount_mas_de_2_decimales,
    COUNT(*) FILTER (WHERE ROUND(l_tax, 2) != l_tax) AS tax_mas_de_2_decimales,
    COUNT(*) FILTER (WHERE l_discount < 0 OR l_discount >= 10) AS discount_fuera_de_rango,
    COUNT(*) FILTER (WHERE l_tax < 0 OR l_tax >= 10) AS tax_fuera_de_rango
FROM bronce.tbl_lineitem;