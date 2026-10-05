import duckdb
con = duckdb.connect()
con.execute("INSTALL tpch")
con.execute("LOAD tpch")
con.execute("CALL dbgen(sf=0.01)")
tables = ['region','nation','part','supplier','partsupp','customer','orders','lineitem']
for t in tables:
    con.execute(f"COPY (SELECT * FROM {t}) TO 'sources/tbl/{t}.tbl' (FORMAT CSV, DELIMITER '|', HEADER false)")
    print(t, con.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0])
