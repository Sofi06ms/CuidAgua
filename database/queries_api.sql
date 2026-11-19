-- 1. INSERTAR: Cuando Flutter envía un reporte nuevo
-- (El RETURNING es clave para que el Backend le devuelva el folio al celular)
INSERT INTO reportes (folio, usuario_id, zona_id, categoria, descripcion, latitud, longitud, estado) 
VALUES ('FOLIO-API-01', 1, 1, 'fuga', 'Reporte enviado desde la app Flutter', 20.1234, -98.1234, 'pendiente')
RETURNING id, folio, estado, fecha_creacion;

-- 2. CONSULTAR: Para mostrar en el panel administrativo o "Mis reportes"
SELECT r.id, r.folio, u.nombre AS ciudadano, z.nombre_zona, r.categoria, r.estado, r.fecha_creacion
FROM reportes r
JOIN usuarios u ON r.usuario_id = u.id
LEFT JOIN zonas z ON r.zona_id = z.id;

-- 3. ACTUALIZAR: Para cuando la cuadrilla cambia el estado del reporte
UPDATE reportes 
SET estado = 'en_revision', fecha_actualizacion = CURRENT_TIMESTAMP
WHERE folio = 'FOLIO-API-01'
RETURNING id, folio, estado, fecha_actualizacion;