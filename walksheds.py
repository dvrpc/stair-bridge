import psycopg2

conn = psycopg2.connect("dbname=staircase user=postgres port=5555")

cur = conn.cursor()

cur.execute("create extension postgis;")

conn.commit()

cur.close()
conn.close()
