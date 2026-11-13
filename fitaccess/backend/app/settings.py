"""Configuración local. Nunca guardes credenciales en Git."""
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BASE_DIR / '.env')

DATABASE_URL = os.getenv('DATABASE_URL', '').strip()
ADMIN_API_KEY = os.getenv('ADMIN_API_KEY', '').strip()
MODEL_CONFIG_PATH = BASE_DIR / os.getenv('MODEL_CONFIG_PATH', 'modelo_exportado/config_reconocimiento.json')
WINDOW_DUPLICATE_MINUTES = int(os.getenv('WINDOW_DUPLICATE_MINUTES', '5'))
MAX_IMAGE_BYTES = int(os.getenv('MAX_IMAGE_MB', '8')) * 1024 * 1024


def validar_entorno():
    if not DATABASE_URL:
        raise RuntimeError('Configura DATABASE_URL en backend/.env')
    if len(ADMIN_API_KEY) < 20 or ADMIN_API_KEY.startswith('CAMBIA_'):
        raise RuntimeError('Configura ADMIN_API_KEY segura en backend/.env (20+ caracteres)')
    if not MODEL_CONFIG_PATH.is_file():
        raise RuntimeError(f'Falta {MODEL_CONFIG_PATH}. Copia la exportación de Jupyter.')
    if WINDOW_DUPLICATE_MINUTES < 1:
        raise RuntimeError('WINDOW_DUPLICATE_MINUTES debe ser positivo')
