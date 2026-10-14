/*
==============================================
CREATE SCHEMAs
==============================================

Este script crea tres squemas de bases de datos: bronze, plata y oro
dentro
*/

CREATE SCHEMA IF NOT EXISTS bronce;
CREATE SCHEMA IF NOT EXISTS plata;
CREATE SCHEMA IF NOT EXISTS oro;

DROP VIEW IF EXISTS oro.vw_rfv01_top100_clientes;
DROP VIEW IF EXISTS oro.vw_rfv01_ventas_cliente;
DROP VIEW IF EXISTS oro.vw_rfv02_ventas_geograficas;
DROP VIEW IF EXISTS oro.vw_rfv03_ventas_proveedor;
DROP VIEW IF EXISTS oro.vw_rfv04_ventas_retrasadas;
DROP VIEW IF EXISTS oro.vw_rfv05_ventas_segmento;
DROP VIEW IF EXISTS oro.vw_rfv06_ventas_marca_tipo;
DROP VIEW IF EXISTS oro.vw_rfv07_descuentos_ventas;
DROP VIEW IF EXISTS oro.vw_rfv08_iva_ventas;
DROP VIEW IF EXISTS oro.vw_rfv10_estacionalidad;
DROP VIEW IF EXISTS oro.vw_rfv12_kpis_ejecutivo;
