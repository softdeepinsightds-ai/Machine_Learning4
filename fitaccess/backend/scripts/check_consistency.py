"""Verifica que el nuevo entorno produzca los mismos embeddings que Jupyter.

Uso desde backend/: python -m scripts.check_consistency --fotos "C:\\ruta\\matriculacion"
"""
import argparse
import json
from pathlib import Path
import numpy as np
from app.face import FaceEngine
from app.settings import MODEL_CONFIG_PATH

parser = argparse.ArgumentParser()
parser.add_argument('--fotos', required=True, type=Path, help='Carpeta matriculacion/ del notebook')
parser.add_argument('--cantidad', type=int, default=3)
args = parser.parse_args()

registros = json.loads((MODEL_CONFIG_PATH.parent / 'galeria_embeddings.json').read_text(encoding='utf8'))['registros']
engine = FaceEngine()
if not args.fotos.is_dir():
    raise SystemExit(f'Carpeta de fotografías no encontrada: {args.fotos}')

mayor = 0.0
for r in registros[:max(1, args.cantidad)]:
    ruta = args.fotos / r['persona'] / r['foto']
    if not ruta.is_file():
        raise SystemExit(f'Fotografía original ausente: {ruta}')
    extraido = engine.extraer(ruta.read_bytes())
    if extraido['estado'] != 'OK':
        raise SystemExit(f'Extracción distinta del notebook: {ruta} => {extraido["estado"]}')
    original = np.asarray(r['embedding'], dtype=np.float32)
    distancia = float(np.clip(1.0 - original @ extraido['embedding'], 0.0, 2.0))
    mayor = max(mayor, distancia)
    print(f'{r["persona"]}/{r["foto"]}: distancia a su propio embedding = {distancia:.8f}')

if mayor > 1e-3:
    raise SystemExit(f'AVISO: divergencia {mayor:.6f}. Comprueba versiones, MTCNN y preprocesamiento antes de confiar en 0.260.')
print('OK: extracción consistente para las fotografías verificadas.')
