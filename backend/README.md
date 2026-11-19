# Backend de CuidAgua

API REST que recibe y procesa las solicitudes de la app Flutter de CuidAgua: **reportes ciudadanos** de incidencias de agua y **avisos de suministro** publicados por administradores.

| Componente     | Tecnología                                   |
|----------------|----------------------------------------------|
| Lenguaje       | Java 21                                      |
| Framework      | Spring Boot 3.5 (Maven)                      |
| Base de datos  | PostgreSQL 16 + migraciones con Flyway       |
| Autenticación  | Keycloak 26 (tokens JWT, OAuth2 Resource Server) |
| Entorno de desarrollo | GitHub Codespaces / Dev Containers    |

---

## 1. Estructura del proyecto

El código está organizado **por módulos funcionales**. Cada módulo de negocio tiene sus propias capas `entity`, `dto`, `repository`, `service` y `controller`.

```
backend/
├── pom.xml                         # Dependencias y build de Maven
├── docker-compose.dev.yml          # Contenedores de desarrollo: app, db, keycloak
├── keycloak/
│   └── realm-cuidagua.json         # Realm, roles, cliente y usuarios de prueba
├── pruebas/
│   └── CuidAgua-API.postman_collection.json   # Colección de pruebas (Postman / Thunder Client)
└── src/
    ├── main/
    │   ├── java/com/cuidagua/api/
    │   │   ├── CuidaguaApiApplication.java    # Punto de entrada
    │   │   ├── config/                        # Configuración transversal
    │   │   │   ├── SecurityConfig.java        # Rutas públicas/protegidas, JWT, CORS
    │   │   │   ├── OpenApiConfig.java         # Swagger / OpenAPI con autenticación Bearer
    │   │   │   ├── KeycloakRealmRoleConverter.java  # Lee realm_access.roles del token
    │   │   │   └── JsonSecurityHandlers.java  # Respuestas JSON para 401 y 403
    │   │   ├── common/                        # Código compartido por todos los módulos
    │   │   │   ├── dto/ApiResponse.java       # Formato único de respuesta
    │   │   │   ├── exception/                 # Manejo global de errores (400, 404, 409...)
    │   │   │   └── util/                      # TextoUtils, JwtUtils
    │   │   ├── reporte/                       # Módulo de reportes ciudadanos
    │   │   │   ├── entity/                    # Reporte, TipoReporte, EstadoReporte (flujo de estados)
    │   │   │   ├── dto/                       # Request/Response, CambioEstadoRequest, ReporteFiltro, Resumen
    │   │   │   ├── repository/                # ReporteRepository (Spring Data JPA)
    │   │   │   ├── specification/             # Consulta dinámica según los filtros
    │   │   │   ├── service/                   # ReporteService (lógica de negocio)
    │   │   │   └── controller/                # ReporteController (/api/reportes)
    │   │   └── aviso/                         # Módulo de avisos de suministro
    │   │       ├── entity/                    # Aviso, TipoAviso
    │   │       ├── dto/                       # AvisoRequest, AvisoResponse, AvisoFiltro
    │   │       ├── repository/                # AvisoRepository
    │   │       ├── specification/             # Consulta dinámica según los filtros
    │   │       ├── service/                   # AvisoService
    │   │       └── controller/                # AvisoController (/api/avisos)
    │   └── resources/
    │       ├── application.yml                # Configuración (lee variables de entorno)
    │       └── db/migration/
    │           ├── V1__crear_tablas.sql       # Tablas reportes y avisos
    │           └── V2__zona_y_seguimiento.sql # Columna zona, seguimiento de estado, índices
    └── test/
        ├── java/com/cuidagua/api/
        │   ├── reporte/, aviso/               # Pruebas de controladores y seguridad (sin BD)
        │   └── integracion/ApiPostgresIT.java # Pruebas de integración API + PostgreSQL
        └── resources/application-it.yml       # Perfil "it": usa el esquema "pruebas"
```

**Responsabilidad de cada capa:**

| Capa         | Qué hace |
|--------------|----------|
| `entity`     | Clases JPA que representan las tablas y los enums del dominio. |
| `dto`        | Lo que entra (`*Request`, con validaciones) y lo que sale (`*Response`) de la API. Las entidades nunca se exponen directamente. |
| `repository` | Acceso a datos con Spring Data JPA. |
| `service`    | Reglas de negocio y transacciones. |
| `controller` | Endpoints REST: reciben la petición, llaman al servicio y arman la respuesta `ApiResponse`. |

Para agregar un módulo nuevo (por ejemplo, `notificacion`), crea la carpeta con las mismas cinco subcarpetas.

---

## 2. Abrir el proyecto en GitHub Codespaces

1. En GitHub, entra al repositorio y cambia a la rama de trabajo.
2. Botón **Code** → pestaña **Codespaces** → menú **⋯** → **New with options…**
3. En **Dev container configuration** elige **CuidAgua - Backend (Java 21 + Spring Boot)** (`.devcontainer/backend/devcontainer.json`).
4. Pulsa **Create codespace**. La primera vez tarda unos minutos.

Codespaces levanta automáticamente tres contenedores, definidos en `backend/docker-compose.dev.yml`:

| Servicio   | Qué es                          | Dirección              |
|------------|---------------------------------|------------------------|
| `app`      | Java 21 + Maven (aquí programas) | API en `http://localhost:8080` |
| `db`       | PostgreSQL 16                   | `localhost:5432` (base `cuidagua`, usuario `cuidagua`, contraseña `cuidagua`) |
| `keycloak` | Keycloak 26 en modo dev         | `http://localhost:8180` (consola: `admin` / `admin`) |

Los tres comparten la misma red, así que todo está en `localhost`. Los puertos 8080, 8180 y 5432 se reenvían automáticamente (pestaña **Ports** de VS Code).

El realm `cuidagua` se importa solo al arrancar Keycloak e incluye:

| Usuario      | Contraseña     | Roles              |
|--------------|----------------|--------------------|
| `ciudadano1` | `ciudadano123` | CIUDADANO          |
| `admin1`     | `admin123`     | ADMIN, CIUDADANO   |

> Las credenciales y la configuración de Keycloak son **solo para desarrollo**.

---

## 3. Correr la API

En la terminal del Codespace (ya estás en la carpeta `backend`):

```bash
mvn spring-boot:run
```

Al arrancar, Flyway crea o actualiza las tablas `reportes` y `avisos` (migraciones V1, V2...). Comprueba que la API funciona:

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

**Documentación interactiva (Swagger):** abre `http://localhost:8080/swagger-ui.html`. Ahí aparecen todas las rutas con sus parámetros y puedes probarlas. Para las rutas protegidas, pulsa **Authorize** y pega el `access_token` de Keycloak (ver sección 6). El JSON de OpenAPI está en `http://localhost:8080/v3/api-docs`.

### Pruebas automáticas

| Comando      | Qué ejecuta | Necesita |
|--------------|-------------|----------|
| `mvn test`   | Pruebas de controladores, validaciones y seguridad (`*Test.java`) | Nada (sin BD ni Keycloak) |
| `mvn verify` | Lo anterior + pruebas de integración API ↔ PostgreSQL (`*IT.java`) | PostgreSQL en marcha |

Las pruebas de integración recorren controlador → servicio → repositorio → PostgreSQL con las migraciones reales de Flyway. Usan el esquema **`pruebas`** de la base `cuidagua` (se crea solo), así que **no tocan los datos de desarrollo** del esquema `public`. Solo se simula el token de Keycloak. Para usar otra base, define `DB_URL_TEST`.

### Variables de entorno

`application.yml` lee la conexión de variables de entorno. En el Codespace ya vienen definidas en `docker-compose.dev.yml`:

| Variable              | Valor en desarrollo                           |
|-----------------------|-----------------------------------------------|
| `DB_URL`              | `jdbc:postgresql://localhost:5432/cuidagua`   |
| `DB_USER`             | `cuidagua`                                    |
| `DB_PASSWORD`         | `cuidagua`                                    |
| `KEYCLOAK_ISSUER_URI` | `http://localhost:8180/realms/cuidagua` (valor por defecto) |

---

## 4. Endpoints

### Reportes (`/api/reportes`)

| Método | Ruta                         | Acceso                    | Descripción |
|--------|------------------------------|---------------------------|-------------|
| POST   | `/api/reportes`              | Token (cualquier usuario) | Registra una incidencia (inicia en `PENDIENTE`). |
| GET    | `/api/reportes`              | Público                   | Lista reportes, más recientes primero. Acepta filtros (ver abajo). |
| GET    | `/api/reportes/{id}`         | Público                   | Detalle de un reporte. 404 si no existe. |
| GET    | `/api/reportes/mios`         | Token (cualquier usuario) | Reportes creados por el usuario del token. |
| PATCH  | `/api/reportes/{id}/estado`  | Token con rol **ADMIN**   | Cambia el estado de un reporte. |
| GET    | `/api/reportes/resumen`      | Token con rol **ADMIN**   | Conteos por estado y por tipo para el panel. |

**Filtros de `GET /api/reportes`** (opcionales y combinables):

| Parámetro | Valores | Ejemplo |
|-----------|---------|---------|
| `estado`  | `PENDIENTE`, `EN_PROCESO`, `RESUELTO`, `RECHAZADO` | `?estado=PENDIENTE` |
| `tipo`    | `FUGA`, `TUBERIA_ROTA`, `SIN_AGUA`, `BAJA_PRESION`, `OTRO` | `?tipo=FUGA` |
| `zona`    | texto | `?zona=Zona Centro` |
| `colonia` | texto | `?colonia=Centro` |

Ejemplo combinado: `GET /api/reportes?estado=PENDIENTE&tipo=FUGA&zona=Zona%20Centro`

### Avisos (`/api/avisos`)

| Método | Ruta               | Acceso                  | Descripción |
|--------|--------------------|-------------------------|-------------|
| POST   | `/api/avisos`      | Token con rol **ADMIN** | Publica un aviso de suministro. |
| GET    | `/api/avisos`      | Público                 | Lista avisos, más recientes primero. Acepta filtros (ver abajo). |
| GET    | `/api/avisos/{id}` | Público                 | Detalle de un aviso. 404 si no existe. |
| PUT    | `/api/avisos/{id}` | Token con rol **ADMIN** | Edita un aviso (mismos campos que al crear; conserva el autor). |
| DELETE | `/api/avisos/{id}` | Token con rol **ADMIN** | Elimina un aviso. |

**Filtros de `GET /api/avisos`** (opcionales y combinables):

| Parámetro  | Valores | Ejemplo |
|------------|---------|---------|
| `zona`     | texto | `?zona=Zona Centro` |
| `colonia`  | texto | `?colonia=Centro` |
| `tipo`     | `CORTE`, `RESTABLECIMIENTO`, `MANTENIMIENTO`, `BAJA_PRESION` | `?tipo=CORTE` |
| `vigentes` | `true` (aún no llega la fecha de restablecimiento) / `false` (ya vencidos) | `?vigentes=true` |

### Otros

| Método | Ruta                 | Acceso  | Descripción |
|--------|----------------------|---------|-------------|
| GET    | `/actuator/health`   | Público | Estado de la API. |
| GET    | `/swagger-ui.html`   | Público | Documentación interactiva. |
| GET    | `/v3/api-docs`       | Público | Especificación OpenAPI en JSON. |

Los filtros de texto (`zona`, `colonia`) no distinguen mayúsculas de minúsculas (`zona centro` = `Zona Centro`). Un valor de enum desconocido en un filtro responde 400 con la lista de valores permitidos.

### Seguridad

- Los tokens son JWT emitidos por Keycloak (realm `cuidagua`, cliente `cuidagua-app`).
- Se envían en el encabezado `Authorization: Bearer <token>`.
- Los roles se leen de `realm_access.roles` del token.
- Del token se guarda el usuario que crea el reporte o aviso: `sub` (id) y `preferred_username` (nombre).

### Campos de `POST /api/reportes`

| Campo         | Tipo    | Obligatorio | Reglas |
|---------------|---------|-------------|--------|
| `tipo`        | texto   | Sí | `FUGA`, `TUBERIA_ROTA`, `SIN_AGUA`, `BAJA_PRESION`, `OTRO` |
| `descripcion` | texto   | Sí | 10 a 500 caracteres |
| `direccion`   | texto   | Sí | máx. 255 caracteres |
| `colonia`     | texto   | Sí | máx. 120 caracteres |
| `zona`        | texto   | Sí | máx. 80 caracteres |
| `latitud`     | número  | No | entre -90 y 90; se envía junto con `longitud` |
| `longitud`    | número  | No | entre -180 y 180; se envía junto con `latitud` |
| `fotoUrl`     | texto   | No | URL válida, máx. 500 caracteres |

El servidor asigna `estado = PENDIENTE`, la fecha de creación y el usuario del token. Los textos se guardan sin espacios al inicio ni al final.

### Cambio de estado: `PATCH /api/reportes/{id}/estado`

```json
{ "estado": "EN_PROCESO", "comentario": "Cuadrilla asignada" }
```

| Campo        | Obligatorio | Reglas |
|--------------|-------------|--------|
| `estado`     | Sí | nuevo estado |
| `comentario` | Solo al pasar a `RECHAZADO` | máx. 500 caracteres |

Flujo permitido:

```
PENDIENTE  ──► EN_PROCESO ──► RESUELTO
    │              │
    ├──► RESUELTO  └──► RECHAZADO
    └──► RECHAZADO
```

`RESUELTO` y `RECHAZADO` son finales. Una transición no permitida (o al mismo estado) responde **409**. La respuesta incluye `comentarioEstado`, `actualizadoPor` (admin del token) y `fechaActualizacion`.

### Respuesta de `GET /api/reportes/resumen`

```json
{
  "exito": true,
  "mensaje": "Resumen de reportes",
  "datos": {
    "total": 3,
    "porEstado": { "PENDIENTE": 2, "EN_PROCESO": 1, "RESUELTO": 0, "RECHAZADO": 0 },
    "porTipo": { "FUGA": 3, "TUBERIA_ROTA": 0, "SIN_AGUA": 0, "BAJA_PRESION": 0, "OTRO": 0 }
  }
}
```

### Campos de `POST /api/avisos`

| Campo                   | Tipo   | Obligatorio | Reglas |
|-------------------------|--------|-------------|--------|
| `titulo`                | texto  | Sí | 5 a 120 caracteres |
| `mensaje`               | texto  | Sí | 10 a 1000 caracteres |
| `colonia`               | texto  | Sí | máx. 120 caracteres |
| `zona`                  | texto  | Sí | máx. 80 caracteres |
| `tipo`                  | texto  | Sí | `CORTE`, `RESTABLECIMIENTO`, `MANTENIMIENTO`, `BAJA_PRESION` |
| `fechaInicio`           | fecha  | No | debe ser anterior a `fechaRestablecimiento` |
| `fechaRestablecimiento` | fecha  | Sí | debe estar en el futuro |

Las fechas usan el formato `yyyy-MM-ddTHH:mm:ss` (ej. `2026-11-20T08:00:00`), en hora del centro de México (`TZ=America/Mexico_City`).

---

## 5. Formato de respuestas

Todas las respuestas tienen la misma forma, para que Flutter las procese igual:

- **Éxito:** `{ "exito": true, "mensaje": "...", "datos": ... }`
- **Error:** `{ "exito": false, "mensaje": "...", "errores": { "campo": "motivo" } }`

| Código | Cuándo |
|--------|--------|
| 201 | Se creó un reporte o aviso |
| 200 | Consulta, cambio de estado, edición o eliminación correctos |
| 400 | Datos inválidos (validación, JSON mal formado o filtro con valor desconocido) |
| 401 | No se envió token, o es inválido o expiró |
| 403 | El token es válido pero el usuario no tiene el rol necesario |
| 404 | No existe el reporte o aviso con ese `id` |
| 409 | El cambio de estado no está permitido en el estado actual del reporte |

### 201 – Reporte creado

```json
{
  "exito": true,
  "mensaje": "Reporte registrado correctamente",
  "datos": {
    "id": 1,
    "tipo": "FUGA",
    "descripcion": "Fuga de agua en la banqueta frente al número 25",
    "direccion": "Av. Juárez 25",
    "colonia": "Centro",
    "zona": "Zona Centro",
    "latitud": 19.4326,
    "longitud": -99.1332,
    "fotoUrl": "https://ejemplo.com/fotos/fuga1.jpg",
    "estado": "PENDIENTE",
    "usuario": "ciudadano1",
    "fechaCreacion": "2026-11-12T10:15:30.123456",
    "comentarioEstado": null,
    "actualizadoPor": null,
    "fechaActualizacion": null
  }
}
```

### 201 – Aviso creado

```json
{
  "exito": true,
  "mensaje": "Aviso publicado correctamente",
  "datos": {
    "id": 1,
    "titulo": "Corte programado de agua",
    "mensaje": "Se suspenderá el servicio por mantenimiento de la red principal.",
    "colonia": "Centro",
    "zona": "Zona Centro",
    "tipo": "CORTE",
    "fechaInicio": null,
    "fechaRestablecimiento": "2026-11-15T08:00:00",
    "vigente": true,
    "creadoPor": "admin1",
    "fechaCreacion": "2026-11-12T10:20:00.654321",
    "fechaActualizacion": null
  }
}
```

### 200 – Consulta

```json
{
  "exito": true,
  "mensaje": "Se encontraron 1 reportes",
  "datos": [
    { "id": 1, "tipo": "FUGA", "colonia": "Centro", "estado": "PENDIENTE", "...": "..." }
  ]
}
```

### 400 – Error de validación

```json
{
  "exito": false,
  "mensaje": "Los datos enviados no son válidos",
  "errores": {
    "tipo": "El tipo de reporte es obligatorio",
    "descripcion": "La descripción debe tener entre 10 y 500 caracteres",
    "direccion": "La dirección es obligatoria",
    "latitud": "La latitud debe estar entre -90 y 90"
  }
}
```

Con un valor de enum desconocido:

```json
{
  "exito": false,
  "mensaje": "Los datos enviados no son válidos",
  "errores": {
    "tipo": "Valor no válido. Valores permitidos: CORTE, RESTABLECIMIENTO, MANTENIMIENTO, BAJA_PRESION"
  }
}
```

### 401 – Sin token

```json
{
  "exito": false,
  "mensaje": "Debes iniciar sesión para realizar esta acción",
  "errores": {
    "token": "No se envió el token de acceso (Authorization: Bearer <token>)"
  }
}
```

### 403 – Sin permiso

```json
{
  "exito": false,
  "mensaje": "No tienes permiso para realizar esta acción",
  "errores": {
    "rol": "Tu usuario no tiene el rol requerido"
  }
}
```

### 404 – No encontrado

```json
{
  "exito": false,
  "mensaje": "No existe un reporte con id 99",
  "errores": { "id": "No encontrado" }
}
```

### 409 – Cambio de estado no permitido

```json
{
  "exito": false,
  "mensaje": "No se puede realizar la operación",
  "errores": {
    "estado": "El reporte está en estado RESUELTO y ya no puede cambiar"
  }
}
```

---

## 6. Probar los endpoints

La API debe estar corriendo (`mvn spring-boot:run`).

### Opción A: colección automática con Newman (terminal)

El Codespace incluye Node.js, así que puedes correr toda la colección en otra terminal:

```bash
npx --yes newman run pruebas/CuidAgua-API.postman_collection.json
```

La colección pide los tokens, los guarda y verifica cada caso:

- **Reportes:** crear válido (201), inválido (400), sin token (401); listados y filtros por estado/tipo/zona (200); filtro inválido (400); detalle (200) e inexistente (404); mis reportes; cambio de estado como ciudadano (403), como admin (200), transición no permitida (409), rechazo sin comentario (400); resumen del panel.
- **Avisos:** crear como admin (201), como ciudadano (403), con fecha pasada (400); listados y filtro de vigentes por zona/tipo; detalle; editar (200); eliminar como ciudadano (403) y como admin (200); detalle de aviso eliminado (404).

Las peticiones guardan los ids creados en las variables `reporteId` y `avisoId`, por eso se ejecutan en orden.

### Opción B: Thunder Client o Postman

1. Abre **Thunder Client** en la barra lateral → **Collections** → menú **≡** → **Import** y elige `backend/pruebas/CuidAgua-API.postman_collection.json`. En Postman: **Import** con el mismo archivo.
2. Ejecuta primero **1. Autenticación** (los dos tokens) y luego los demás en orden.
3. Los scripts guardan los tokens en las variables `tokenCiudadano` y `tokenAdmin`. Si tu versión de Thunder Client no ejecuta scripts, copia el `access_token` de la respuesta y pégalo en la variable de la colección.

### Opción C: curl

```bash
# 1. Obtener token de ciudadano1
TOKEN=$(curl -s -X POST http://localhost:8180/realms/cuidagua/protocol/openid-connect/token \
  -d grant_type=password -d client_id=cuidagua-app \
  -d username=ciudadano1 -d password=ciudadano123 | sed -E 's/.*"access_token":"([^"]+)".*/\1/')

# 2. Crear un reporte
curl -i -X POST http://localhost:8080/api/reportes \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"tipo":"FUGA","descripcion":"Fuga de agua frente al número 25","direccion":"Av. Juárez 25","colonia":"Centro","zona":"Zona Centro"}'

# 3. Listar reportes pendientes de fugas en una zona
curl -s "http://localhost:8080/api/reportes?estado=PENDIENTE&tipo=FUGA&zona=Zona%20Centro"

# 4. Cambiar el estado (requiere token de admin1 en $TOKEN_ADMIN)
curl -s -X PATCH http://localhost:8080/api/reportes/1/estado \
  -H "Authorization: Bearer $TOKEN_ADMIN" -H "Content-Type: application/json" \
  -d '{"estado":"EN_PROCESO","comentario":"Cuadrilla asignada"}'
```

Para el token de administrador usa `username=admin1` y `password=admin123`.

---

## 7. Notas para el equipo

- **Issuer del token:** la API acepta tokens cuyo `iss` sea `http://localhost:8180/realms/cuidagua`. Cuando la app Flutter se conecte desde un emulador o dispositivo usando la URL pública del Codespace, el `iss` cambiará. En ese caso hay que configurar `KC_HOSTNAME` en Keycloak y ajustar `KEYCLOAK_ISSUER_URI`.
- **docker-compose.yml de la raíz:** sigue usando `postgres:17` y `cuidagua_db`. El entorno de desarrollo del backend (`docker-compose.dev.yml`) usa PostgreSQL 16 con la base `cuidagua`. Conviene unificarlos cuando se cierren las decisiones pendientes de `docs/DECISIONES_TECNICAS.md`.
- **Nuevas tablas o columnas:** crea un archivo nuevo en `src/main/resources/db/migration/` (`V2__descripcion.sql`, `V3__...`). No modifiques una migración que ya se ejecutó.
- **Campo `zona`:** se agregó en la migración V2 y es obligatorio en los reportes y avisos nuevos. Los registros creados antes de V2 tienen `zona = null` y no aparecen al filtrar por zona.
- **App Flutter:** ahora debe enviar `zona` al crear reportes. Las respuestas agregan campos nuevos (`zona`, `comentarioEstado`, `actualizadoPor`, `fechaActualizacion`, `vigente`); los campos anteriores no cambiaron.
- **Swagger en producción:** desactívalo con `springdoc.api-docs.enabled=false` y `springdoc.swagger-ui.enabled=false`.
