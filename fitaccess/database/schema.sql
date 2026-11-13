-- Ejecutar en la base de datos gimnasio_facial, una vez instalado pgvector en PostgreSQL 16.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS usuarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    cedula VARCHAR(10) UNIQUE CHECK (cedula IS NULL OR cedula ~ '^[0-9]{10}$'),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS face_embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    origen VARCHAR(250) NOT NULL,
    embedding VECTOR(512) NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_id, origen)
);
CREATE INDEX IF NOT EXISTS idx_embeddings_usuario ON face_embeddings(usuario_id);
-- Para esta galería pequeña buscamos el vecino exacto. NO creamos HNSW aproximado.

CREATE TABLE IF NOT EXISTS asistencias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NULL REFERENCES usuarios(id) ON DELETE SET NULL,
    estado VARCHAR(12) NOT NULL CHECK (estado IN ('ACCEPTED', 'REJECTED', 'DUPLICATE')),
    distancia DOUBLE PRECISION NULL,
    motivo VARCHAR(120) NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_asistencias_fecha ON asistencias(fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_asistencias_usuario_fecha ON asistencias(usuario_id, fecha_hora DESC);
