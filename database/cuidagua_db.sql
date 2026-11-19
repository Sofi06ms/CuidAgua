-- ==========================================
-- 1. CREACION DE TABLAS
-- ==========================================
-- Tabla de Usuarios
CREATE TABLE usuarios (
id SERIAL PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
correo VARCHAR(150) UNIQUE NOT NULL,
credencial_hash VARCHAR(255) NOT NULL,
rol VARCHAR(20) NOT NULL CHECK (rol IN ('ciudadano', 'personal', 'administrador')),
fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Tabla de Zonas
CREATE TABLE zonas (
id SERIAL PRIMARY KEY,
nombre_zona VARCHAR(100) NOT NULL
);
-- Tabla de Reportes
CREATE TABLE reportes (
id SERIAL PRIMARY KEY,
folio VARCHAR(20) UNIQUE NOT NULL,
usuario_id INT NOT NULL REFERENCES usuarios(id),
zona_id INT REFERENCES zonas(id),
categoria VARCHAR(50) NOT NULL,
descripcion TEXT NOT NULL,
latitud DECIMAL(10, 8),
longitud DECIMAL(11, 8),
estado VARCHAR(30) DEFAULT 'pendiente',
fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Tabla de Evidencias
CREATE TABLE evidencias (
id SERIAL PRIMARY KEY,
reporte_id INT NOT NULL REFERENCES reportes(id),
url_archivo VARCHAR(255) NOT NULL,
fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Tabla de Historial de Estados
CREATE TABLE historial_estados (
id SERIAL PRIMARY KEY,
reporte_id INT NOT NULL REFERENCES reportes(id),
estado_anterior VARCHAR(30),
estado_nuevo VARCHAR(30) NOT NULL,
observacion TEXT,
responsable_id INT REFERENCES usuarios(id),
fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Tabla de Asignaciones
CREATE TABLE asignaciones (
id SERIAL PRIMARY KEY,
reporte_id INT NOT NULL REFERENCES reportes(id),
responsable_id INT NOT NULL REFERENCES usuarios(id),
fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Tabla de Avisos de suministro
CREATE TABLE avisos (
id SERIAL PRIMARY KEY,
zona_id INT REFERENCES zonas(id) ON DELETE CASCADE,
titulo VARCHAR(150) NOT NULL,
mensaje TEXT NOT NULL,
fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ==========================================
-- 2. INDICES - Para optimizar busquedas
-- ==========================================
CREATE INDEX idx_reportes_usuario ON reportes(usuario_id);
CREATE INDEX idx_reportes_zona ON reportes(zona_id);
CREATE INDEX idx_evidencias_reporte ON evidencias(reporte_id);
CREATE INDEX idx_historial_reporte ON historial_estados(reporte_id);
CREATE INDEX idx_asignaciones_reporte ON asignaciones(reporte_id);
CREATE INDEX idx_avisos_zona ON avisos(zona_id); -- <--- Indice anadido para optimizar
-- =============================================
-- 3. DATOS DE PRUEBA - Para probar el Backend
-- =============================================
-- Insertar Usuarios
INSERT INTO usuarios (nombre, correo, credencial_hash, rol) VALUES
('Usuario Ciudadano', 'ciudadano@gmail.com', 'hash_prueba', 'ciudadano'),
('Personal Atencion', 'personal@gmail.com', 'hash_prueba', 'personal'),
('Administrador', 'admin@gmail.com', 'hash_prueba', 'administrador');
-- Insertar Zonas
INSERT INTO zonas (nombre_zona) VALUES
('Zona Norte'), ('Zona Centro'), ('Zona Sur');
-- Insertar Reportes
INSERT INTO reportes (folio, usuario_id, zona_id, categoria, descripcion, latitud, longitud, estado) VALUES
('FOLIO-001', 1, 1, 'fuga', 'Fuga de agua en la calle principal.', 20.1765, -98.0535, 'pendiente'),
('FOLIO-002', 1, 2, 'tuberia_danada', 'Tuberia rota en la colonia.', 20.1800, -98.0500, 'en_revision'),
('FOLIO-003', 1, 3, 'falta_suministro', 'No hay agua en la zona.', 20.1700, -98.0600, 'resuelto');
-- Insertar Evidencias
INSERT INTO evidencias (reporte_id, url_archivo) VALUES
(1, 'url_de_prueba_foto1.jpg'),
(2, 'url_de_prueba_foto2.jpg');
-- Insertar Historial de Estados
INSERT INTO historial_estados (reporte_id, estado_anterior, estado_nuevo, observacion, responsable_id) VALUES
(1, 'pendiente', 'en_revision', 'Observacion de prueba', 2),
(3, 'pendiente', 'resuelto', 'Observacion de prueba', 2);
-- Insertar Avisos
INSERT INTO avisos (zona_id, titulo, mensaje) VALUES
(1, 'Corte por mantenimiento en Zona Norte', 'Mensaje de aviso de prueba sobre el suministro de agua afectando la zona norte por 24 horas.');
-- Insertar Asignaciones
INSERT INTO asignaciones (reporte_id, responsable_id) VALUES
(2, 2);
