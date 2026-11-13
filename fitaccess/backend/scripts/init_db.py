"""Crea tablas en la base existente. Requiere pgvector instalado en el servidor."""
from pathlib import Path
import psycopg
from app.settings import DATABASE_URL

ruta = Path(__file__).resolve().parents[2] / 'database' / 'schema.sql'
sentencias = [x.strip() for x in ruta.read_text(encoding='utf8').split(';') if x.strip()]
with psycopg.connect(DATABASE_URL) as conn:
    for sql in sentencias:
        conn.execute(sql)
print('OK: extensión vector y tablas usuarios, face_embeddings y asistencias listas.')
