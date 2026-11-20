-- V2: ajustes al esquema oficial (V1) que necesita la API, acordados con el equipo.
-- Solo agrega columnas, restricciones, índices y una secuencia; no elimina nada de V1.

-- ------------------------------------------------------------------
-- 1. Vínculo de usuarios con Keycloak
-- ------------------------------------------------------------------
-- El inicio de sesión lo hace Keycloak. Cada usuario se identifica por el claim "sub" del token.
-- En credencial_hash la API guarda el texto fijo 'KEYCLOAK': indica autenticación externa,
-- no es un hash ni una contraseña.
ALTER TABLE usuarios
    ADD COLUMN keycloak_id VARCHAR(64) UNIQUE;

-- ------------------------------------------------------------------
-- 2. Datos de los avisos que usa la app (tipo, vigencia y autor)
-- ------------------------------------------------------------------
ALTER TABLE avisos
    ADD COLUMN tipo                   VARCHAR(30) NOT NULL,
    ADD COLUMN fecha_inicio           TIMESTAMP,
    ADD COLUMN fecha_restablecimiento TIMESTAMP   NOT NULL,
    ADD COLUMN creado_por_id          INT         NOT NULL REFERENCES usuarios(id),
    ADD COLUMN fecha_actualizacion    TIMESTAMP,
    ADD CONSTRAINT ck_avisos_tipo
        CHECK (tipo IN ('corte', 'restablecimiento', 'mantenimiento', 'baja_presion')),
    ADD CONSTRAINT ck_avisos_fechas
        CHECK (fecha_inicio IS NULL OR fecha_inicio < fecha_restablecimiento);

-- ------------------------------------------------------------------
-- 3. Valores permitidos de estados y categorías
-- ------------------------------------------------------------------
ALTER TABLE reportes
    ADD CONSTRAINT ck_reportes_estado
        CHECK (estado IN ('pendiente', 'en_revision', 'resuelto', 'rechazado')),
    ADD CONSTRAINT ck_reportes_categoria
        CHECK (categoria IN ('fuga', 'tuberia_danada', 'falta_suministro', 'baja_presion', 'otro')),
    ADD CONSTRAINT ck_reportes_latitud
        CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
    ADD CONSTRAINT ck_reportes_longitud
        CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180);

ALTER TABLE historial_estados
    ADD CONSTRAINT ck_historial_estado_anterior
        CHECK (estado_anterior IS NULL OR estado_anterior IN ('pendiente', 'en_revision', 'resuelto', 'rechazado')),
    ADD CONSTRAINT ck_historial_estado_nuevo
        CHECK (estado_nuevo IN ('pendiente', 'en_revision', 'resuelto', 'rechazado'));

-- ------------------------------------------------------------------
-- 4. Folio de reportes: CA-<año>-<consecutivo de 6 dígitos>, ej. CA-2026-000001
-- ------------------------------------------------------------------
CREATE SEQUENCE folio_reportes_seq START WITH 1 INCREMENT BY 1;

-- ------------------------------------------------------------------
-- 5. Índices para los filtros de la API
-- ------------------------------------------------------------------
CREATE INDEX idx_reportes_estado                ON reportes (estado);
CREATE INDEX idx_reportes_categoria             ON reportes (categoria);
CREATE INDEX idx_reportes_fecha_creacion        ON reportes (fecha_creacion DESC);
CREATE INDEX idx_avisos_tipo                    ON avisos (tipo);
CREATE INDEX idx_avisos_fecha_restablecimiento  ON avisos (fecha_restablecimiento);
CREATE INDEX idx_avisos_creado_por              ON avisos (creado_por_id);
