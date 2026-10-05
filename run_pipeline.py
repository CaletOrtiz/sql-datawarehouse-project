import duckdb, os
os.makedirs('data', exist_ok=True)
db = 'data/dwh.duckdb'
if os.path.exists(db): os.remove(db)
con = duckdb.connect(db)
for script in ['scripts/init_schemas.sql',
               'scripts/bronce/ddl_bronze.sql',
               'scripts/bronce/load_bronce.sql',
               'scripts/plata/ddl_plata.sql',
               'scripts/plata/etl.sql',
               'scripts/oro/ddl_oro.sql',
               'scripts/oro/etl_oro.sql']:
    print('>>>', script)
    sql = open(script, encoding='utf-8').read()
    try:
        res = con.execute(sql)
    except Exception as e:
        # run statement by statement
        ok = True
        for stmt in sql.split(';'):
            if stmt.strip():
                try: con.execute(stmt)
                except Exception as e2: print('  ERROR stmt:', e2); ok=False
        continue
    try:
        for row in res.fetchall(): print('  ', row)
    except Exception: pass
print('schemas:', con.execute("SELECT schema_name FROM information_schema.schemata").fetchall())
print('tables:', con.execute("SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1,2").fetchall())
