# KPIs para Power BI

Medidas en `powerbi/KPI_DAX.dax`. Importar los 11 parquet de `data/parquet/`
(o del artefacto del workflow) al modelo.

> **Archivo listo:** abrir `powerbi/InformeVentas.pbip` en Power BI Desktop.
> Ya trae el modelo (11 tablas, 3 relaciones, 20 medidas) y 4 páginas con
> 19 visuales. Al abrir pedirá la ruta de los parquet: apuntar a
> `data/parquet/` de este repo (o Ajustar con Origen de datos si cambia de PC).

## Modelo: relaciones

| Desde | Hacia | Tipo |
|---|---|---|
| `factura[fecha_venta]` | `dim_tiempo[tiempo_pk]` | muchos a uno, filtro simple |
| `factura[cliente_fk]` | `dim_cliente[cliente_pk]` | muchos a uno, filtro simple |
| `factura[producto_fk]` | `dim_producto[producto_pk]` | muchos a uno, filtro simple |

Marcar `dim_tiempo[fecha_completa]` como tabla de fechas (botón derecho >
Marcar como tabla de fechas). Ordenar `mes_nombre` por la columna `mes`.
Las vistas `vw_rfv*` se importan como tablas sueltas (sin relación).

## Set de KPIs

| # | KPI | Medida DAX | Visual sugerido | RF |
|---|---|---|---|---|
| 1 | Venta neta total | `Venta Neta` | Tarjeta | V01–V17 |
| 2 | Venta bruta total | `Venta Bruta` | Tarjeta | base |
| 3 | Impuesto (IVA) total | `Monto Impuesto` | Tarjeta | V10 |
| 4 | Ticket medio por línea | `Ticket Medio` | Tarjeta | V01 |
| 5 | Nro. órdenes / líneas | `Nro Ordenes`, `Nro Lineas` | Tarjetas | V01 |
| 6 | % descuento efectivo | `Pct Descuento Efectivo` | Tarjeta + serie mensual (`vw_rfv07`) | V09 |
| 7 | Venta neta YoY % | `Var Neta YoY %` | Tarjeta con formato condicional | V15 |
| 8 | Venta neta YTD | `Venta Neta YTD` | Tarjeta | V15 |
| 9 | Serie anual 1992–1997 | `Venta Neta` por `dim_tiempo[anio]` | Columnas apiladas + línea YoY | V15 |
| 10 | Venta por región/país | `Venta Neta` por `regio_nombre`, `pais_nombre` | Mapa coroplético + matriz | V02 |
| 11 | Top 10 clientes | `Venta Neta` por cliente | Barras + tarjeta `% concentración` | V01 |
| 12 | Venta por segmento | `vw_rfv05` (`venta_neta_total` por segmento/año) | Columnas apiladas 100% | V07 |
| 13 | Venta por marca/tipo | `vw_rfv06` | Matriz fabricante > marca > tipo | V08 |
| 14 | % líneas retrasadas | `Pct Lineas Retrasadas` | Tarjeta + tendencia mensual | V05 |
| 15 | Venta afectada por retrasos | `Venta Afectada Retrasos` | Tarjeta | V05 |
| 16 | Días de retraso promedio | `Dias Retraso Promedio` | Tarjeta | V04 |
| 17 | Ranking proveedores | `vw_rfv03` | Tabla top 10 | V03 |

## Páginas sugeridas del informe

1. **Portada**: puerta de entrada con navegador de páginas + adelanto de la curva.
2. **Historia 1992-1997**: el relato en 3 capítulos (volumen total → crecimiento vs 1992 → ticket por orden), curva acumulada, YoY, segmentos y tabla de hitos.
3. **Ejecutivo (RF-V17):** KPIs 1–8 + serie anual.
4. **Clientes y geografía:** KPIs 10–12.
5. **Producto:** KPI 13 + empaque si se agrega.
6. **Logística:** KPIs 14–16 + detalle `vw_rfv04`.
7. **Próximos capítulos**: plantillas para Clientes y Logística.

## Medidas narrativas (tabla `factura`)

`Venta Acumulada`, `Ticket Medio por Orden`, `Pct del Total del Periodo`,
`Venta Año Base 1992`, `Crecimiento vs 1992 %`, `Unidades por Orden`.

## Notas

- Periodo 1992–1997: `SAMEPERIODLASTYEAR` funciona porque `dim_tiempo`
  es continua (2192 días). 1992 no tendrá año anterior: es lo esperado.
- `vw_rfv04` solo trae líneas con `shipdate > commitdate` (27735 filas).
- Devoluciones (RF-V06, `returnflag = R`) no están en `factura` actual;
  si se necesitan, hay que agregar la columna en el ETL.
