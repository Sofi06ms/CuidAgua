# Decisiones técnicas del proyecto CuidAgua

## 1. Información general

- **Proyecto:** CuidAgua.
- **Tipo:** Aplicación móvil para reportar incidencias relacionadas con el servicio de agua.
- **Objetivo:** Facilitar el reporte y seguimiento de incidencias relacionadas con el suministro hídrico.
- **Arquitectura general:** Cliente-servidor.
- **Metodología de desarrollo:** Scrum.
- **Equipo:** Cinco integrantes.

## 2. Arquitectura del sistema

El proyecto utiliza una arquitectura cliente-servidor para permitir la comunicación entre la aplicación móvil, el backend y la base de datos.

### 2.1 Aplicación móvil

- **Framework:** Flutter.
- **Lenguaje:** Dart.
- **Arquitectura:** Clean Architecture.
- **Capas:** Dominio, Datos y Presentación.
- **Comunicación:** Consumo de servicios mediante API REST.
- **Programación asíncrona:** Future, async y await.

### 2.2 Backend

- **Lenguaje:** Java.
- **Framework:** Spring Boot.
- **Arquitectura:** Por capas.
- **Patrón de diseño:** Repository.
- **Comunicación:** API REST.

La versión definitiva de Spring Boot queda pendiente de confirmación.

### 2.3 Panel administrativo

- **Plataforma:** Aplicación web.
- **Objetivo:** Administrar y dar seguimiento a los reportes e incidencias.

## 3. Tecnologías seleccionadas

| Componente | Tecnología |
|---|---|
| Aplicación móvil | Flutter |
| Lenguaje móvil | Dart |
| Backend | Java con Spring Boot |
| Base de datos | PostgreSQL 17 |
| Contenedores | Docker |
| Orquestación | Docker Compose |
| Control de versiones | Git y GitHub |
| Panel administrativo | Aplicación web |

## 4. Decisiones funcionales

- La identificación de zonas utilizará un enfoque combinado.
- Los horarios de suministro de agua serán administrados manualmente.
- La aplicación móvil se comunicará con el backend mediante una API REST.
- PostgreSQL almacenará la información relacionada con usuarios, reportes, zonas y demás entidades del sistema.
- El panel administrativo permitirá gestionar la información de las incidencias.

## 5. Decisiones de infraestructura

- Docker se utilizará para facilitar la configuración y ejecución del entorno de desarrollo.
- PostgreSQL 17 será el sistema gestor de base de datos.
- Docker Compose permitirá administrar los servicios del entorno.
- Las credenciales y configuraciones sensibles se manejarán mediante variables de entorno.
- El archivo `.env` no deberá publicarse ni subirse al repositorio.
- El archivo `.env.example` servirá como plantilla de configuración para los integrantes.
- Los datos de PostgreSQL se conservarán mediante un volumen persistente de Docker.

### 5.1 Configuración de PostgreSQL

| Parámetro | Valor |
|---|---|
| Imagen Docker | postgres:17 |
| Base de datos | cuidagua_db |
| Usuario | cuidagua_user |
| Puerto | 5432 |
| Contenedor | cuidagua_postgres |
| Volumen | postgres_data |

### 5.2 Conexión con el backend

La conexión entre Spring Boot y PostgreSQL deberá configurarse mediante variables de entorno y parámetros de conexión.

La integración deberá verificarse cuando el servicio backend esté disponible.

## 6. Organización del repositorio

- `backend/`: código del servidor Spring Boot.
- `database/`: scripts y recursos relacionados con PostgreSQL.
- `docs/`: documentación técnica del proyecto.
- `scripts/`: comandos y herramientas auxiliares.
- `docker-compose.yml`: configuración de los servicios en contenedores.
- `README.md`: descripción general e instrucciones de configuración.
- `CONTRIBUTING.md`: normas de colaboración y flujo de trabajo.
- `.env.example`: plantilla de variables de entorno.

## 7. Flujo de trabajo Git

El proyecto utiliza Git Flow para organizar el desarrollo colaborativo.

### Ramas principales

- `main`: contiene las versiones estables.
- `develop`: contiene la integración de funcionalidades.

### Ramas de trabajo

- `feature/`: desarrollo de nuevas funcionalidades.
- `fix/`: corrección de errores.
- `docs/`: modificaciones de documentación.
- `release/`: preparación de versiones.
- `hotfix/`: correcciones urgentes de versiones estables.

Los cambios se integrarán mediante Pull Requests, siguiendo las reglas establecidas en `CONTRIBUTING.md`.

## 8. Decisiones pendientes de validación

- Versión definitiva de Spring Boot.
- Configuración y prueba de conexión entre backend y PostgreSQL.
- Integración de los servicios de la aplicación.
- Configuración definitiva de los servicios en Docker Compose conforme a la arquitectura completa.
- Estrategia de despliegue de la aplicación.

---

**CuidAgua — Tecnología al servicio de una mejor gestión del agua.**