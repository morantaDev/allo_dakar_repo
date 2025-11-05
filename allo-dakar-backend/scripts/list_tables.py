import os
import sys
ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, ROOT)

p = os.path.join(ROOT, 'instance', 'allo_dakar.db')
print('path->', p)
print('exists->', os.path.exists(p))
if os.path.exists(p):
    import sqlite3
    conn = sqlite3.connect(p)
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    print('tables->', cur.fetchall())
    conn.close()
