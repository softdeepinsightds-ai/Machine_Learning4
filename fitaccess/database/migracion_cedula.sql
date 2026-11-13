-- MIGRACIÓN INCREMENTAL: ejecutar una vez por base de datos (TEST primero).
-- Preserva TODOS los socios originales, embeddings y asistencias.
-- Las siete identidades antiguas continuarán con cedula NULL hasta su verificación manual.
-- No es necesario cambiar FaceNet512 ni su umbral.
BEGIN;
ALTER TABLE public.usuarios
    ADD COLUMN IF NOT EXISTS cedula VARCHAR(10);
-- Permitir NULL para socios existentes, exigir 10 dígitos cuando la cédula está informada.
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'ck_usuarios_cedula_10_digitos'
          AND conrelid = 'public.usuarios'::regclass
    ) THEN
        ALTER TABLE public.usuarios
            ADD CONSTRAINT ck_usuarios_cedula_10_digitos
            CHECK (cedula IS NULL OR cedula ~ '^[0-9]{10}$');
    END IF;
END $$;
-- PostgreSQL permite varios NULL en índice UNIQUE: adecuado para socios importados.
CREATE UNIQUE INDEX IF NOT EXISTS ux_usuarios_cedula
    ON public.usuarios (cedula);
COMMIT;
