echo "conectamos a duckdb y creamos la base de datos"
duckdb ./data/dwh.duckdb < ./scripts/init_schemas