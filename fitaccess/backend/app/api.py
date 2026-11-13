"""Backend único: inferencia, matriculación, búsqueda vectorial y asistencia.

Entorno: demostración local con clave de operador, NO autenticación para producción.
"""
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import re
import secrets
from uuid import uuid4

import numpy as np
import psycopg
from fastapi import Depends, FastAPI, File, Header, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field

from .cedula_ec import validar_cedula_ecuador
from .db import abrir_db
from .face import FaceEngine
from .logic import aceptar
from .settings import (
    ADMIN_API_KEY, MAX_IMAGE_BYTES, WINDOW_DUPLICATE_MINUTES, validar_entorno,
)

motor: FaceEngine | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global motor
    validar_entorno()
    motor = FaceEngine()
    yield


app = FastAPI(title='FitAccess — Reconocimiento Facial', version='1.0.0', lifespan=lifespan)


def autenticar(x_api_key: str | None = Header(default=None, alias='X-API-Key')):
    if not x_api_key or not secrets.compare_digest(x_api_key, ADMIN_API_KEY):
        raise HTTPException(status_code=401, detail='Clave de operador inválida')


class NuevoUsuario(BaseModel):
    nombre: str = Field(min_length=2, max_length=150)
    codigo: str = Field(min_length=3, max_length=50)
    cedula: str = Field(pattern=r'^\d{10}$', description='10 dígitos; verificar documento físico')


class AsignarCedula(BaseModel):
    cedula: str = Field(pattern=r'^\d{10}$', description='10 dígitos; verificar documento físico')


async def leer_foto(archivo: UploadFile) -> bytes:
    if archivo.content_type not in ('image/jpeg', 'image/png', 'image/jpg', 'application/octet-stream'):
        raise HTTPException(status_code=415, detail='Solo JPG o PNG')
    data = await archivo.read(MAX_IMAGE_BYTES + 1)
    if not data or len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail='Imagen vacía o superior al tamaño permitido')
    return data


async def inferir(data: bytes) -> dict:
    if motor is None:
        raise HTTPException(status_code=503, detail='Servicio de IA aún no inicializado')
    return await run_in_threadpool(motor.extraer, data)


@app.get('/health')
def health():
    try:
        with abrir_db() as db:
            db.execute('SELECT 1')
        estado_db = 'ok'
    except Exception:
        estado_db = 'sin_conexion'
    return {'servicio': 'gimnasio-facial', 'db': estado_db,
            'modelo': 'Facenet512', 'detector': 'mtcnn',
            'umbral': motor.umbral if motor else None}


@app.post('/embedding', dependencies=[Depends(autenticar)])
async def generar_embedding(foto: UploadFile = File(...)):
    resultado = await inferir(await leer_foto(foto))
    if resultado['estado'] != 'OK':
        raise HTTPException(status_code=422, detail=resultado['estado'] + ': ' + resultado['motivo'])
    return {'dimension': 512, 'embedding': resultado['embedding'].tolist(),
            'calidad': resultado['calidad']}


@app.post('/usuarios', dependencies=[Depends(autenticar)], status_code=201)
def crear_usuario(datos: NuevoUsuario):
    codigo = datos.codigo.strip().lower()
    nombre = datos.nombre.strip()
    cedula = datos.cedula.strip()
    if not validar_cedula_ecuador(cedula):
        raise HTTPException(status_code=422, detail='Cédula ecuatoriana inválida: revise provincia, tercer dígito y módulo 10')
    if not re.fullmatch(r'[a-z0-9_-]{3,50}', codigo):
        raise HTTPException(status_code=422, detail='Código: 3-50 caracteres a-z, 0-9, _ o -')
    if len(nombre) < 2:
        raise HTTPException(status_code=422, detail='Nombre demasiado corto')
    try:
        with abrir_db() as db:
            fila = db.execute('''
                INSERT INTO usuarios(codigo, nombre, cedula) VALUES(%s,%s,%s)
                RETURNING id, codigo, nombre, activo
            ''', (codigo, nombre, cedula)).fetchone()
        return fila
    except psycopg.errors.UniqueViolation as exc:
        constraint = (exc.diag.constraint_name or '').lower()
        detail = ('La cédula ya está registrada' if 'cedula' in constraint
                  else 'El código ya está registrado' if 'codigo' in constraint
                  else 'Ya existe un registro con estos datos')
        raise HTTPException(status_code=409, detail=detail) from exc


@app.patch('/usuarios/{usuario_id}/cedula', dependencies=[Depends(autenticar)])
def asignar_cedula_legacy(usuario_id: int, datos: AsignarCedula):
    # Completar cédula de usuarios importados de Jupyter, una sola vez.
    # Un cambio posterior requiere revisión administrativa fuera de este endpoint.
    if not validar_cedula_ecuador(datos.cedula):
        raise HTTPException(status_code=422, detail='Cédula ecuatoriana inválida: revise provincia, tercer dígito y módulo 10')
    try:
        with abrir_db() as db:
            actualizado = db.execute('''
                UPDATE usuarios SET cedula=%s
                WHERE id=%s AND cedula IS NULL
                RETURNING id, nombre, codigo
            ''', (datos.cedula, usuario_id)).fetchone()
            if actualizado:
                return {'id': actualizado['id'], 'nombre': actualizado['nombre'],
                        'codigo': actualizado['codigo'], 'cedula_asignada': True}
            fila = db.execute('SELECT id, cedula FROM usuarios WHERE id=%s', (usuario_id,)).fetchone()
            if fila is None:
                raise HTTPException(status_code=404, detail='Usuario no encontrado')
            raise HTTPException(status_code=409, detail='Este usuario ya tiene una cédula asignada')
    except psycopg.errors.UniqueViolation as exc:
        raise HTTPException(status_code=409, detail='La cédula ya pertenece a otro usuario') from exc


@app.get('/usuarios', dependencies=[Depends(autenticar)])
def listar_usuarios():
    with abrir_db() as db:
        return db.execute('''
            SELECT u.id, u.codigo, u.nombre, u.activo,
                   COUNT(e.id)::integer AS embeddings
            FROM usuarios u
            LEFT JOIN face_embeddings e ON e.usuario_id = u.id
            GROUP BY u.id ORDER BY u.nombre
        ''').fetchall()


@app.post('/usuarios/{usuario_id}/matricular', dependencies=[Depends(autenticar)])
async def matricular(usuario_id: int, fotos: list[UploadFile] = File(...)):
    # Registro administrado: mínimo 3 fotos para el prototipo; 5 recomendadas.
    if not 3 <= len(fotos) <= 10:
        raise HTTPException(status_code=422, detail='Envía entre 3 y 10 fotografías por operación')
    embeddings = []
    for numero, archivo in enumerate(fotos, 1):
        resultado = await inferir(await leer_foto(archivo))
        if resultado['estado'] != 'OK':
            raise HTTPException(status_code=422, detail=f'Fotografía {numero}: {resultado["estado"]} ({resultado["motivo"]}). Ninguna fue guardada.')
        embeddings.append(resultado['embedding'])

    # Todo o nada: nunca guardar únicamente algunas fotos de este lote.
    with abrir_db() as db:
        usuario = db.execute('SELECT id, nombre, activo FROM usuarios WHERE id=%s FOR UPDATE', (usuario_id,)).fetchone()
        if not usuario or not usuario['activo']:
            raise HTTPException(status_code=404, detail='Usuario inexistente o inactivo')
        for emb in embeddings:
            db.execute('''INSERT INTO face_embeddings(usuario_id, origen, embedding)
                          VALUES(%s,%s,%s)''', (usuario_id, f'movil/{uuid4().hex}.jpg', emb))
        total = db.execute('SELECT COUNT(*) AS n FROM face_embeddings WHERE usuario_id=%s', (usuario_id,)).fetchone()['n']
    return {'usuario_id': usuario_id, 'nombre': usuario['nombre'],
            'nuevos_embeddings': len(embeddings), 'total_embeddings': total,
            'advertencia': 'Si crece mucho la galería, repetir evaluación y calibración en capturas nuevas.'}


def guardar_rechazo(motivo: str, distancia: float | None = None) -> dict:
    # No guardamos imagen, embedding, ni identidad candidata del rostro desconocido.
    with abrir_db() as db:
        fila = db.execute('''
            INSERT INTO asistencias (usuario_id, estado, distancia, motivo)
            VALUES (NULL, 'REJECTED', %s, %s)
            RETURNING id, fecha_hora
        ''', (distancia, motivo)).fetchone()
    return {'estado': 'REJECTED', 'usuario': None, 'distancia': distancia,
            'motivo': motivo, 'asistencia_id': fila['id'], 'fecha_hora': fila['fecha_hora']}


@app.post('/accesos/verificar', dependencies=[Depends(autenticar)])
@app.post('/access/verify', dependencies=[Depends(autenticar)], include_in_schema=False)
async def verificar_acceso(foto: UploadFile = File(...)):
    resultado = await inferir(await leer_foto(foto))
    if resultado['estado'] != 'OK':
        return guardar_rechazo(resultado['estado'])

    consulta = np.asarray(resultado['embedding'], dtype=np.float32)
    # Buscamos entre TODOS los embeddings; equivalencia del notebook 'todos_min'.
    # Operador pgvector <=> = distancia coseno. La búsqueda es EXACTA (sin índice HNSW).
    with abrir_db() as db:
        mejor = db.execute('''
            SELECT u.id AS usuario_id, u.nombre, u.codigo,
                   (e.embedding <=> %s::vector) AS distancia
            FROM face_embeddings e
            JOIN usuarios u ON u.id=e.usuario_id
            WHERE u.activo=TRUE
            ORDER BY e.embedding <=> %s::vector ASC
            LIMIT 1
        ''', (consulta, consulta)).fetchone()
        if not mejor:
            # No puede usar guardar_rechazo dentro de esta transacción: se guardará al salir.
            motivo, distancia, usuario = 'SIN_MATRICULADOS', None, None
        else:
            distancia = float(mejor['distancia'])
            usuario = mejor
            motivo = 'FUERA_DEL_UMBRAL' if not aceptar(distancia, motor.umbral) else None

    if motivo is not None:
        return guardar_rechazo(motivo, distancia)

    # Bloqueo de transacción por socio para evitar dos ACCEPTED simultáneos.
    with abrir_db() as db:
        db.execute('SELECT pg_advisory_xact_lock(%s)', (usuario['usuario_id'],))
        ultimo = db.execute('''
            SELECT fecha_hora FROM asistencias
            WHERE usuario_id=%s AND estado IN ('ACCEPTED','DUPLICATE')
            ORDER BY fecha_hora DESC LIMIT 1
        ''', (usuario['usuario_id'],)).fetchone()
        ahora = datetime.now(timezone.utc)
        duplicada = (ultimo is not None and
                     0 <= (ahora - ultimo['fecha_hora']).total_seconds() < WINDOW_DUPLICATE_MINUTES * 60)
        estado = 'DUPLICATE' if duplicada else 'ACCEPTED'
        fila = db.execute('''
            INSERT INTO asistencias (usuario_id, estado, distancia, motivo)
            VALUES (%s, %s, %s, %s)
            RETURNING id, fecha_hora
        ''', (usuario['usuario_id'], estado, distancia,
              'VENTANA_DUPLICADO' if duplicada else 'RECONOCIDO')).fetchone()

    return {'estado': estado,
            'usuario': {'id': usuario['usuario_id'], 'codigo': usuario['codigo'], 'nombre': usuario['nombre']},
            'distancia': round(distancia, 6), 'umbral': motor.umbral,
            'motivo': 'VENTANA_DUPLICADO' if duplicada else 'RECONOCIDO',
            'asistencia_id': fila['id'], 'fecha_hora': fila['fecha_hora']}


@app.get('/asistencias', dependencies=[Depends(autenticar)])
def historial(limit: int = 50, offset: int = 0):
    if not 1 <= limit <= 200 or offset < 0:
        raise HTTPException(status_code=422, detail='limit: 1..200; offset >= 0')
    with abrir_db() as db:
        return db.execute('''
            SELECT a.id, a.estado, a.fecha_hora, a.distancia, a.motivo,
                   u.id AS usuario_id, u.nombre AS usuario_nombre, u.codigo AS usuario_codigo
            FROM asistencias a
            LEFT JOIN usuarios u ON u.id = a.usuario_id
            ORDER BY a.id DESC LIMIT %s OFFSET %s
        ''', (limit, offset)).fetchall()
