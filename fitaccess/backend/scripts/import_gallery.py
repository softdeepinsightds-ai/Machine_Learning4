"""Importa SOLO la galería evaluada del notebook: 7 identidades, ~109 vectores."""
import json
import re
import unicodedata
from pathlib import Path
import numpy as np
from app.db import abrir_db
from app.settings import MODEL_CONFIG_PATH

base = MODEL_CONFIG_PATH.parent
cfg = json.loads((base / 'config_reconocimiento.json').read_text(encoding='utf8'))
registros = json.loads((base / 'galeria_embeddings.json').read_text(encoding='utf8'))['registros']
if cfg.get('estrategia') != 'todos_min' or cfg.get('embedding_dim') != 512:
    raise RuntimeError('La galería no coincide con el sistema evaluado.')
if not registros or len(registros) != cfg['galeria']['embeddings']:
    raise RuntimeError('Cantidad de embeddings distinta de la configuración exportada.')


def codigo(persona):
    nombre = unicodedata.normalize('NFKD', persona).encode('ascii', 'ignore').decode('ascii')
    return re.sub(r'[^a-z0-9]+', '_', nombre.lower()).strip('_')

with abrir_db() as db:
    insertados = 0
    for item in registros:
        persona, foto = str(item['persona']), str(item['foto'])
        emb = np.asarray(item['embedding'], dtype=np.float32)
        if emb.shape != (512,) or not np.isfinite(emb).all() or abs(float(np.linalg.norm(emb))-1) > 1e-3:
            raise ValueError(f'Embedding inválido: {persona}/{foto}')
        cod = codigo(persona)
        fila = db.execute('''
            INSERT INTO usuarios (codigo, nombre) VALUES (%s, %s)
            ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre
            RETURNING id
        ''', (cod, persona.replace('_', ' ').title())).fetchone()
        origen = f'notebook/{persona}/{foto}'
        cursor = db.execute('''
            INSERT INTO face_embeddings (usuario_id, origen, embedding) VALUES (%s,%s,%s)
            ON CONFLICT (usuario_id, origen) DO NOTHING
        ''', (fila['id'], origen, emb))
        insertados += cursor.rowcount
print(f'Importación terminada: {len(registros)} registros leídos; {insertados} nuevos embeddings.')
print('Reejecutar esta importación no duplica los mismos registros.')
