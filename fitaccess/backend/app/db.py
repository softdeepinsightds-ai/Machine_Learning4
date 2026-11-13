"""Conexión PostgreSQL + adaptador de los vectores de 512 números."""
from contextlib import contextmanager
import psycopg
from psycopg.rows import dict_row
from pgvector.psycopg import register_vector
from .settings import DATABASE_URL


@contextmanager
def abrir_db():
    # Cada petición obtiene su propia transacción. El COMMIT ocurre al salir sin errores.
    with psycopg.connect(DATABASE_URL, connect_timeout=5) as conn:
        # Registrar primero tipos PG con el cursor normal; después devolver filas dict.
        register_vector(conn)
        conn.row_factory = dict_row
        yield conn
