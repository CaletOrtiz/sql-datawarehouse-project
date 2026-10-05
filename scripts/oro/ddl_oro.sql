/*
==============================================
GOLD LAYER (ORO) - STAR SCHEMA DDL
==============================================
Esquema en estrella optimizado para análisis:
  - fact_sales (hechos: líneas de venta)
  - dim_date, dim_customer, dim_product

WARNING: Este script elimina las tablas existentes en el esquema oro.
*/

DROP TABLE IF EXISTS oro.fact_sales;
DROP TABLE IF EXISTS oro.dim_date;
DROP TABLE IF EXISTS oro.dim_customer;
DROP TABLE IF EXISTS oro.dim_product;


-- Dimensión de fechas (role-playing: order/ship/commit/receipt)
CREATE TABLE IF NOT EXISTS oro.dim_date (
    date_key        INTEGER PRIMARY KEY,   -- YYYYMMDD
    full_date       DATE,
    year            INTEGER,
    quarter         INTEGER,
    month           INTEGER,
    month_name      VARCHAR(15),
    day             INTEGER,
    day_name        VARCHAR(15),
    is_weekend      BOOLEAN
);

CREATE TABLE IF NOT EXISTS oro.dim_customer (
    customer_key    INTEGER PRIMARY KEY,   -- surrogate key = c_custkey
    customer_name   VARCHAR(25),
    address         VARCHAR(40),
    phone           CHAR(15),
    market_segment  CHAR(10),
    nation          VARCHAR(25),
    region          VARCHAR(25),
    account_balance DECIMAL(15,2),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oro.dim_product (
    product_key     INTEGER PRIMARY KEY,   -- surrogate key = p_partkey
    product_name    VARCHAR(25),
    manufacturer    CHAR(25),
    brand           VARCHAR(25),
    type            VARCHAR(25),
    size            INTEGER,
    container       VARCHAR(10),
    supplier_name   VARCHAR(25),
    retail_price    DECIMAL(15,2),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oro.fact_sales (
    sales_key       INTEGER PRIMARY KEY,   -- surrogate key
    order_id        INTEGER,               -- o_orderkey
    line_number     INTEGER,               -- l_linenumber
    customer_key    INTEGER,               -- FK dim_customer
    product_key     INTEGER,               -- FK dim_product
    order_date_key  INTEGER,               -- FK dim_date (o_orderdate)
    ship_date_key   INTEGER,               -- FK dim_date (l_shipdate)
    commit_date_key INTEGER,               -- FK dim_date (l_commitdate)
    receipt_date_key INTEGER,              -- FK dim_date (l_receiptdate)
    quantity        DECIMAL(15,2),
    extended_price  DECIMAL(15,2),
    discount        DECIMAL(3,2),
    tax             DECIMAL(3,2),
    revenue         DECIMAL(15,2),         -- extended_price * (1 - discount) * (1 + tax)
    order_status    CHAR(1),
    order_priority  VARCHAR(10),
    return_flag     CHAR(1),
    line_status     CHAR(1),
    ship_mode       CHAR(10),
    ship_instruct   CHAR(25),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
