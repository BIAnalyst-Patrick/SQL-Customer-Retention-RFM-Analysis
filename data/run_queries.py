import sqlite3
import sys
from pathlib import Path

DB_PATH = Path(__file__).parent / "ecommerce.db"
SQL_DIR = Path(__file__).parent.parent / "sql"

def run(sql_file):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    sql = (SQL_DIR / sql_file).read_text()
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    print(" | ".join(cols))
    for r in rows:
        print(" | ".join(str(v) for v in r))
    conn.close()

if __name__ == "__main__":
    run(sys.argv[1])
