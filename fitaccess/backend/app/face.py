"""Reproduce el procesamiento exacto exportado por el notebook académico."""
import json
import threading
from pathlib import Path

import cv2
import numpy as np

from .settings import MODEL_CONFIG_PATH


class FaceEngine:
    def __init__(self, config_path: Path = MODEL_CONFIG_PATH):
        self.config = json.loads(config_path.read_text(encoding='utf-8'))
        cfg = self.config
        esperado = {'modelo': 'Facenet512', 'detector': 'mtcnn',
                    'align': True, 'normalization_deepface': 'base',
                    'embedding_dim': 512, 'distancia': 'cosine',
                    'estrategia': 'todos_min', 'embedding_normalizado_l2': True}
        errores = {k: (cfg.get(k), v) for k, v in esperado.items() if cfg.get(k) != v}
        if errores:
            raise RuntimeError(f'La configuración del notebook no coincide con el backend: {errores}')
        self.umbral = float(cfg['umbral'])
        if not 0 < self.umbral < 1:
            raise RuntimeError('Umbral de distancia coseno inválido')
        self.preprocessing = cfg['preprocesamiento']
        self.lock = threading.Lock()  # Serializar inferencias en CPU y creación del modelo.

    def extraer(self, data: bytes) -> dict:
        imagen = cv2.imdecode(np.frombuffer(data, dtype=np.uint8), cv2.IMREAD_COLOR)
        if imagen is None or imagen.ndim != 3 or imagen.shape[2] != 3:
            return {'estado': 'ARCHIVO_ILEGIBLE', 'motivo': 'No se pudo decodificar JPG/PNG'}

        alto, ancho = imagen.shape[:2]
        max_lado = int(self.preprocessing['max_lado_imagen'])
        escala = min(1.0, max_lado / max(alto, ancho))
        if escala < 1.0:
            imagen = cv2.resize(imagen,
                                (max(1, round(ancho * escala)), max(1, round(alto * escala))),
                                interpolation=cv2.INTER_AREA)

        # Importación diferida: /health no requiere descargar ni cargar FaceNet512.
        from deepface import DeepFace
        try:
            with self.lock:
                rostros = DeepFace.represent(
                    img_path=imagen,
                    model_name='Facenet512',
                    detector_backend='mtcnn',
                    enforce_detection=True,
                    align=True,
                    normalization='base',
                )
        except ValueError as exc:
            texto = str(exc).lower()
            if any(x in texto for x in ('could not be detected', 'no face detected', 'face is not detected')):
                return {'estado': 'SIN_ROSTRO', 'motivo': 'MTCNN no detectó un rostro'}
            raise  # No disfrazar un fallo del modelo como una foto inválida.

        if len(rostros) == 0:
            return {'estado': 'SIN_ROSTRO', 'motivo': 'Detector sin resultados'}
        if len(rostros) != 1:
            return {'estado': 'VARIOS_ROSTROS', 'motivo': f'Detectados {len(rostros)} rostros'}

        rostro = rostros[0]
        area = rostro['facial_area']
        x, y, w, h = (int(area[k]) for k in ('x', 'y', 'w', 'h'))
        hh, ww = imagen.shape[:2]
        x1, y1 = max(0, x), max(0, y)
        x2, y2 = min(ww, x+w), min(hh, y+h)
        if x2 <= x1 or y2 <= y1:
            return {'estado': 'ROSTRO_BAJA_CALIDAD', 'motivo': 'Recorte facial vacío'}
        crop = imagen[y1:y2, x1:x2]
        gris = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
        gris160 = cv2.resize(gris, (160, 160))
        brillo = float(gris.mean())
        nitidez = float(cv2.Laplacian(gris160, cv2.CV_64F).var())
        confianza = float(rostro.get('face_confidence') or 0.0)
        lado = min(x2-x1, y2-y1)
        p = self.preprocessing
        luz_min, luz_max = p['brillo_admitido']
        if (confianza < p['confianza_minima'] or lado < p['min_lado_rostro']
                or not (luz_min <= brillo <= luz_max) or nitidez < p['nitidez_minima']):
            return {'estado': 'ROSTRO_BAJA_CALIDAD',
                    'motivo': 'No cumple confianza/tamaño/luz/nitidez',
                    'calidad': {'confianza': confianza, 'lado_rostro': lado,
                                'brillo': brillo, 'nitidez': nitidez}}

        embedding = np.asarray(rostro['embedding'], dtype=np.float32)
        norma = float(np.linalg.norm(embedding))
        if embedding.shape != (512,) or not np.isfinite(embedding).all() or norma < 1e-10:
            raise RuntimeError('El modelo devolvió un embedding inválido')
        return {'estado': 'OK', 'embedding': embedding / norma,
                'calidad': {'confianza': confianza, 'lado_rostro': lado,
                            'brillo': brillo, 'nitidez': nitidez}}
