/*
==============================================
GOLD LAYER (ORO) - STAR SCHEMA DDL
==============================================
Esquema en estrella:
  - factura (tabla de hechos)
  - dim_tiempo, dim_cliente, dim_producto

WARNING: Este script elimina las tablas existentes en el esquema oro.
*/

DROP TABLE IF EXISTS oro.factura;
DROP TABLE IF EXISTS oro.fact_sales;
DROP TABLE IF EXISTS oro.dim_tiempo;
DROP TABLE IF EXISTS oro.dim_date;
DROP TABLE IF EXISTS oro.dim_cliente;
DROP TABLE IF EXISTS oro.dim_customer;
DROP TABLE IF EXISTS oro.dim_producto;
DROP TABLE IF EXISTS oro.dim_product;
DROP TABLE IF EXISTS oro.dim_supplier;

CREATE TABLE IF NOT EXISTS oro.dim_tiempo (
    tiempo_pk        BIGINT PRIMARY KEY,   -- YYYYMMDD
    anio             SMALLINT,
    mes              SMALLINT,
    dia              SMALLINT,
    fecha_completa   DATE,
    mes_nombre       VARCHAR(15),
    dia_semana       VARCHAR(15),
    trimestre        SMALLINT,
    trimestre_nombre VARCHAR(15),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oro.dim_cliente (
    cliente_pk       BIGINT PRIMARY KEY,
    nombre_cliente   VARCHAR(20),
    segmento_mercado VARCHAR(15),
    pais_nombre      VARCHAR(15),
    regio_nombre     VARCHAR(15),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oro.dim_producto (
    producto_pk      BIGINT PRIMARY KEY,
    nombre_producto  VARCHAR(40),
    fabricante       VARCHAR(30),
    marca            VARCHAR(25),
    tipo_producto    VARCHAR(25),
    nombre_proveedor VARCHAR(40),
    dwh_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oro.factura (
    factura_pk            BIGINT PRIMARY KEY,
    fecha_venta           BIGINT,               -- FK a dim_tiempo.tiempo_pk
    cliente_fk            BIGINT,               -- FK a dim_cliente.cliente_pk
    producto_fk           BIGINT,               -- FK a dim_producto.producto_pk
    cantidad_de_producto  BIGINT,
    precio_bruto          DECIMAL(15,2),
    porcentaje_descuento  DECIMAL(3,2),
    porcentaje_impuesto   DECIMAL(3,2),
    venta_neta            DECIMAL(15,2),
    monto_impuesto        DECIMAL(15,2),
    dwh_created_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
