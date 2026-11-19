
# Guía de contribución – CuidAgua

## 1. Objetivo

Establecer las reglas de colaboración, organización de ramas e integración de cambios en el repositorio CuidAgua mediante el modelo Git Flow.

## 2. Ramas principales

- `main`: contiene las versiones estables y entregables del proyecto.
- `develop`: rama principal de integración donde se incorporan las funcionalidades desarrolladas.

## 3. Ramas de trabajo

- `feature/nombre-funcionalidad`: desarrollo de nuevas funcionalidades. Se crean desde `develop` y se integran nuevamente en `develop`.
- `fix/nombre-correccion`: correcciones de errores durante el desarrollo. Se crean desde `develop` y se integran en `develop`.
- `docs/nombre-documentacion`: modificaciones de documentación. Se crean desde `develop` y se integran en `develop`.
- `release/version`: preparación, revisión y estabilización de una nueva versión. Se crean desde `develop` y se integran en `main` y `develop`.
- `hotfix/nombre-correccion`: correcciones urgentes sobre una versión estable. Se crean desde `main` y se integran en `main` y `develop`.

## 4. Reglas de trabajo

1. No realizar cambios directamente en `main`.
2. No realizar cambios directamente en `develop`.
3. Cada integrante debe trabajar en una rama correspondiente a su tarea.
4. Las ramas `feature`, `fix` y `docs` deben partir de `develop`.
5. Las ramas `release` deben partir de `develop`.
6. Las ramas `hotfix` deben partir de `main`.
7. Los cambios deben publicarse en GitHub mediante `git push`.
8. Las integraciones deben realizarse mediante Pull Requests o el procedimiento de finalización de Git Flow correspondiente.
9. Antes de integrar cambios, deben revisarse para detectar errores y conflictos.
10. La rama `main` solamente recibirá versiones estables y revisadas.

## 5. Flujo de trabajo

### 5.1 Desarrollo de funcionalidades

1. Actualizar la rama `develop`.
2. Crear una rama `feature/nombre-funcionalidad` desde `develop`.
3. Realizar los cambios correspondientes.
4. Registrar los cambios mediante commits.
5. Publicar la rama en GitHub.
6. Crear un Pull Request hacia `develop`.
7. Revisar y aprobar los cambios antes de integrarlos.

### 5.2 Correcciones durante el desarrollo

1. Crear una rama `fix/nombre-correccion` desde `develop`.
2. Realizar y probar la corrección.
3. Publicar los cambios.
4. Crear un Pull Request hacia `develop`.
5. Revisar e integrar la corrección.

### 5.3 Preparación de versiones

1. Crear una rama `release/version` desde `develop`.
2. Realizar las pruebas y ajustes finales.
3. Integrar la versión estable en `main`.
4. Etiquetar la versión cuando corresponda.
5. Incorporar los cambios de la versión nuevamente en `develop`.

### 5.4 Correcciones urgentes

1. Crear una rama `hotfix/nombre-correccion` desde `main`.
2. Realizar la corrección urgente.
3. Probar los cambios.
4. Integrar la corrección en `main`.
5. Incorporar también la corrección en `develop`.

## 6. Responsabilidades

- **Scrum Master / DevOps:** coordinar el flujo de trabajo, supervisar las integraciones y verificar la estabilidad del repositorio.
- **Integrantes del equipo:** trabajar en sus ramas asignadas, documentar sus cambios y realizar Pull Requests.
- **Revisión de cambios:** verificar que las modificaciones sean compatibles con el proyecto antes de integrarlas.

## 7. Integración y control de versiones

Las ramas temporales se utilizarán únicamente cuando exista una tarea, versión o corrección que lo requiera.

Las ramas `feature`, `fix` y `docs` se integrarán en `develop`.

Las ramas `release` y `hotfix` deberán incorporarse tanto en `main` como en `develop`, según corresponda.

Una vez finalizado el trabajo, las ramas temporales podrán eliminarse después de verificar que sus cambios fueron integrados correctamente.

---

**CuidAgua – Guía de colaboración y control de versiones.**