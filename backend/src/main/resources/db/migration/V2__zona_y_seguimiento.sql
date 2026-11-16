-- V2: campo "zona" para filtrar reportes y avisos, seguimiento del estado de los reportes
-- y control de cambios en avisos.
--
-- "zona" admite NULL solo por los registros que ya existían antes de esta migración;
-- la API la exige en todos los registros nuevos.

ALTER TABLE reportes
    ADD COLUMN zona                VARCHAR(80),
    ADD COLUMN comentario_estado   VARCHAR(500),
    ADD COLUMN actualizado_por     VARCHAR(255),
    ADD COLUMN fecha_actualizacion TIMESTAMP;

CREATE INDEX idx_reportes_zona   ON reportes (LOWER(zona));
CREATE INDEX idx_reportes_estado ON reportes (estado);
CREATE INDEX idx_reportes_tipo   ON reportes (tipo);

ALTER TABLE avisos
    ADD COLUMN zona                VARCHAR(80),
    ADD COLUMN fecha_actualizacion TIMESTAMP;

CREATE INDEX idx_avisos_zona                   ON avisos (LOWER(zona));
CREATE INDEX idx_avisos_tipo                   ON avisos (tipo);
CREATE INDEX idx_avisos_fecha_restablecimiento ON avisos (fecha_restablecimiento);
