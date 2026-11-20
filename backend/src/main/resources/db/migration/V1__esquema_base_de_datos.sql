-- V1: esquema oficial de CuidAgua diseñado por el rol de base de datos.
-- Origen: database/cuidagua_db.sql de la rama feature/base-de-datos_postgresql (commit 169dca1).
-- Se copian sin cambios las tablas y los índices. De los datos de prueba solo se conserva
-- el catálogo de zonas; los usuarios (con credencial_hash) y los registros que dependen
-- de ellos no se incluyen, porque los usuarios se crean desde Keycloak (ver V2).
-- Los ajustes acordados para la API van en V2; no modificar este archivo.

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
CREATE INDEX idx_avisos_zona ON avisos(zona_id);
-- ==========================================
-- 3. CATALOGO DE ZONAS
-- ==========================================
INSERT INTO zonas (nombre_zona) VALUES
('Zona Norte'), ('Zona Centro'), ('Zona Sur');
