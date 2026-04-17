import sqlite3

conn = sqlite3.connect("student.db")
tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()

result = []
for (t,) in tables:
    cols = conn.execute(f"PRAGMA table_info({t})").fetchall()
    col_str = ", ".join([f"{c[1]}({c[2]})" for c in cols])
    result.append(f"TABLE: {t} -> {col_str}")

for line in result:
    print(line)

conn.close()
