/*
=======================================
carga de archivos de datos en las tablas del esquema bronce
=======================================
Este script realiza la carga de los datos de los archivos .tbl ubicados en la carpeta ../../sources/tbl/ a las tablas del esquema bronce.
*/



COPY bronce.tbl_nation FROM 'sources/tbl/nation.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_region FROM 'sources/tbl/region.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_part FROM 'sources/tbl/part.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_supplier FROM 'sources/tbl/supplier.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_partsupp FROM 'sources/tbl/partsupp.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_customer FROM 'sources/tbl/customer.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_orders FROM 'sources/tbl/orders.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);
COPY bronce.tbl_lineitem FROM 'sources/tbl/lineitem.tbl' (FORMAT CSV, DELIMITER '|', HEADER FALSE);