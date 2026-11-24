# Backend de CuidAgua

API REST que recibe y procesa las solicitudes de la app Flutter de CuidAgua: **reportes ciudadanos** de incidencias de agua y **avisos de suministro** publicados por administradores.

| Componente     | Tecnología                                   |
|----------------|----------------------------------------------|
| Lenguaje       | Java 21                                      |
| Framework      | Spring Boot 3.5 (Maven)                      |
| Base de datos  | PostgreSQL 16 + migraciones con Flyway       |
| Autenticación  | Keycloak 26 (tokens JWT, OAuth2 Resource Server) |
| Entorno de desarrollo | GitHub Codespaces / Dev Containers    |

El esquema de base de datos es el **diseño oficial del equipo** (rol de base de datos, `database/cuidagua_db.sql` de la rama `feature/base-de-datos_postgresql`). El backend se adapta a ese diseño. Ver la [sección 7](#7-base-de-datos).

---

## 1. Estructura del proyecto

El código está organizado **por módulos funcionales**. Cada módulo de negocio tiene sus propias capas `entity`, `dto`, `repository`, `service` y `controller`.

```
backend/
├── pom.xml                         # Dependencias y build de Maven
├── Dockerfile                      # Imagen de la API (compila con Maven + Java 21, ejecuta con JRE 21)
├── docker-compose.yml              # Backend completo con un comando: db, keycloak y api
├── .env.example                    # Variables opcionales para docker-compose.yml (IP_LAN)
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
    │   │   │   ├── SecurityConfig.java        # Rutas públicas/protegidas por rol, JWT, CORS
    │   │   │   ├── OpenApiConfig.java         # Swagger / OpenAPI con autenticación Bearer
    │   │   │   ├── WebConfig.java             # Valores del catálogo en parámetros de URL
    │   │   │   ├── KeycloakJwtConfig.java     # Valida el token: llaves (JWKS) e issuers permitidos
    │   │   │   ├── KeycloakRealmRoleConverter.java  # Lee realm_access.roles del token
    │   │   │   └── JsonSecurityHandlers.java  # Respuestas JSON para 401 y 403
    │   │   ├── common/                        # Código compartido por todos los módulos
    │   │   │   ├── catalogo/                  # ValorCatalogo: enums guardados en minúsculas
    │   │   │   ├── dto/ApiResponse.java       # Formato único de respuesta
    │   │   │   ├── exception/                 # Manejo global de errores (400, 404, 409...)
    │   │   │   └── util/TextoUtils.java
    │   │   ├── usuario/                       # Tabla usuarios, vinculada con Keycloak
    │   │   │   ├── entity/                    # Usuario, RolUsuario
    │   │   │   ├── dto/                       # UsuarioToken (datos del token), UsuarioResponse
    │   │   │   ├── repository/
    │   │   │   ├── service/UsuarioService.java  # Crea/actualiza el usuario a partir del token
    │   │   │   └── controller/                # UsuarioController (/api/usuarios/me)
    │   │   ├── zona/                          # Catálogo de zonas (/api/zonas)
    │   │   ├── reporte/                       # Módulo de reportes ciudadanos
    │   │   │   ├── entity/                    # Reporte, Evidencia, HistorialEstado, Asignacion,
    │   │   │   │                              # CategoriaReporte, EstadoReporte (flujo de estados)
    │   │   │   ├── converter/                 # Conversión de los enums a los valores de la BD
    │   │   │   ├── dto/                       # Request/Response, CambioEstadoRequest, Historial, Resumen
    │   │   │   ├── repository/                # ReporteRepository, HistorialEstadoRepository
    │   │   │   ├── specification/             # Consulta dinámica según los filtros
    │   │   │   ├── service/                   # ReporteService (lógica de negocio)
    │   │   │   └── controller/                # ReporteController (/api/reportes)
    │   │   └── aviso/                         # Módulo de avisos de suministro
    │   │       ├── entity/                    # Aviso, TipoAviso
    │   │       ├── converter/
    │   │       ├── dto/                       # AvisoRequest, AvisoResponse, AvisoFiltro, HorarioAviso
    │   │       ├── repository/
    │   │       ├── specification/
    │   │       ├── service/
    │   │       └── controller/                # AvisoController (/api/avisos)
    │   └── resources/
    │       ├── application.yml                # Configuración (lee variables de entorno)
    │       └── db/migration/
    │           ├── V1__esquema_base_de_datos.sql  # Esquema oficial del equipo (sin cambios)
    │           └── V2__ajustes_api.sql            # Ajustes acordados para la API
    └── test/
        ├── java/com/cuidagua/api/
        │   ├── TokensPrueba.java              # Tokens de Keycloak simulados
        │   ├── reporte/, aviso/, zona/, usuario/  # Pruebas de controladores y seguridad (sin BD)
        │   ├── usuario/, aviso/, common/      # Pruebas unitarias (token, horario, catálogos, flujo de estados)
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

---

## 2. Abrir el proyecto en GitHub Codespaces

> **¿Solo quieres usar la API sin programar en Java?** Con Docker Desktop basta con `docker compose up --build` en la carpeta `backend` (no hace falta Java ni Maven). Ver la [sección 10](#10-para-el-equipo-de-flutter).

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

El realm `cuidagua` se importa al crear el contenedor de Keycloak e incluye:

| Usuario      | Contraseña     | Roles en Keycloak   | Rol en la tabla `usuarios` |
|--------------|----------------|---------------------|----------------------------|
| `ciudadano1` | `ciudadano123` | CIUDADANO           | `ciudadano`     |
| `personal1`  | `personal123`  | PERSONAL, CIUDADANO | `personal`      |
| `admin1`     | `admin123`     | ADMIN, CIUDADANO    | `administrador` |

> Las credenciales y la configuración de Keycloak son **solo para desarrollo**.

---

## 3. Correr la API

En la terminal del Codespace (ya estás en la carpeta `backend`):

```bash
mvn spring-boot:run
```

Al arrancar, Flyway aplica las migraciones V1 y V2 si faltan, y Hibernate verifica (`ddl-auto: validate`) que las entidades coinciden con las tablas. Comprueba que la API funciona:

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

> Si vienes de una versión anterior del backend y la API no arranca con un error de Flyway (*checksum mismatch* o *Validate failed*), reinicia la base de desarrollo como se explica en la [sección 7](#reiniciar-la-base-de-datos-de-desarrollo).

**Documentación interactiva (Swagger):** abre `http://localhost:8080/swagger-ui.html`. Para las rutas protegidas, pulsa **Authorize** y pega el `access_token` de Keycloak (ver sección 6). El JSON de OpenAPI está en `http://localhost:8080/v3/api-docs`.

### Pruebas automáticas

| Comando      | Qué ejecuta | Necesita |
|--------------|-------------|----------|
| `mvn test`   | Pruebas de controladores, validaciones, seguridad y unitarias (`*Test.java`) | Nada (sin BD ni Keycloak) |
| `mvn verify` | Lo anterior + pruebas de integración API ↔ PostgreSQL (`*IT.java`) | PostgreSQL en marcha |

Las pruebas de integración recorren controlador → servicio → repositorio → PostgreSQL con las migraciones reales. Usan el esquema **`pruebas`** de la base `cuidagua`, que **se vacía y se vuelve a migrar en cada ejecución**, así que no tocan los datos de desarrollo del esquema `public`. Solo se simula el token de Keycloak. Para usar otra base, define `DB_URL_TEST`.

> Si después de borrar o renombrar una migración aparece *"Found more than one migration with version 1"*, quedan archivos viejos en `target/`: ejecuta `mvn clean verify` (o borra la carpeta `target`).

### Variables de entorno

`application.yml` lee la conexión de variables de entorno. En el Codespace ya vienen definidas en `docker-compose.dev.yml`:

| Variable              | Valor en desarrollo                           |
|-----------------------|-----------------------------------------------|
| `DB_URL`              | `jdbc:postgresql://localhost:5432/cuidagua`   |
| `DB_USER`             | `cuidagua`                                    |
| `DB_PASSWORD`         | `cuidagua`                                    |
| `KEYCLOAK_ISSUER_URI` | `http://localhost:8180/realms/cuidagua` (valor por defecto) |
| `KEYCLOAK_ISSUERS`    | Sin definir: usa `KEYCLOAK_ISSUER_URI`. Lista de issuers aceptados, separados por comas |
| `KEYCLOAK_JWK_SET_URI`| Sin definir: `KEYCLOAK_ISSUER_URI` + `/protocol/openid-connect/certs` |

Las dos últimas sirven para conectar la app desde un emulador o un celular; se explican en la [sección 9](#9-validación-del-token-desde-emulador-o-celular).

---

## 4. Endpoints

Estados, categorías y tipos usan **los mismos valores en minúsculas que la base de datos**, tanto en el JSON como en los filtros.

| Catálogo | Valores |
|----------|---------|
| Estado del reporte | `pendiente`, `en_revision`, `resuelto`, `rechazado` |
| Categoría del reporte | `fuga`, `tuberia_danada`, `falta_suministro`, `baja_presion`, `otro` |
| Tipo de aviso | `corte`, `restablecimiento`, `mantenimiento`, `baja_presion` |

### Zonas (`/api/zonas`)

| Método | Ruta         | Acceso  | Descripción |
|--------|--------------|---------|-------------|
| GET    | `/api/zonas` | Público | Lista las zonas (`id`, `nombre`). El `id` se usa como `zonaId` al crear y filtrar. |

### Usuarios (`/api/usuarios`)

| Método | Ruta               | Acceso                    | Descripción |
|--------|--------------------|---------------------------|-------------|
| GET    | `/api/usuarios/me` | Token (cualquier usuario) | Datos del usuario del token: `id`, `nombre`, `correo` y `rol` (`ciudadano`, `personal` o `administrador`). Si es su primera petición, crea su fila en `usuarios`. |

```json
{
  "exito": true,
  "mensaje": "Usuario autenticado",
  "datos": { "id": 1, "nombre": "Carla Ciudadana", "correo": "ciudadano1@cuidagua.local", "rol": "ciudadano" }
}
```

Sin token responde **401**. La app lo puede llamar justo después de iniciar sesión para decidir qué pantallas mostrar según el `rol`.

### Reportes (`/api/reportes`)

| Método | Ruta                           | Acceso                          | Descripción |
|--------|--------------------------------|---------------------------------|-------------|
| POST   | `/api/reportes`                | Token (cualquier usuario)       | Registra una incidencia: inicia en `pendiente` y recibe un folio. |
| GET    | `/api/reportes`                | Público                         | Lista reportes, más recientes primero. Acepta filtros (ver abajo). |
| GET    | `/api/reportes/{id}`           | Público                         | Detalle de un reporte. 404 si no existe. |
| GET    | `/api/reportes/mios`           | Token (cualquier usuario)       | Reportes creados por el usuario del token. |
| GET    | `/api/reportes/{id}/historial` | Token (cualquier usuario)       | Cambios de estado del reporte, del más antiguo al más reciente. |
| PATCH  | `/api/reportes/{id}/estado`    | Token con rol **ADMIN** o **PERSONAL** | Cambia el estado y lo guarda en `historial_estados`. |
| GET    | `/api/reportes/resumen`        | Token con rol **ADMIN** o **PERSONAL** | Conteos por estado y por categoría para el panel. |

**Filtros de `GET /api/reportes`** (opcionales y combinables):

| Parámetro   | Valores | Ejemplo |
|-------------|---------|---------|
| `estado`    | estado del reporte | `?estado=en_revision` |
| `categoria` | categoría del reporte | `?categoria=fuga` |
| `zonaId`    | id de `GET /api/zonas` | `?zonaId=2` |

Ejemplo combinado: `GET /api/reportes?estado=pendiente&categoria=fuga&zonaId=2`

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
| `zonaId`   | id de `GET /api/zonas`. No incluye los avisos generales (sin zona) | `?zonaId=1` |
| `tipo`     | tipo de aviso | `?tipo=corte` |
| `vigentes` | `true` (aún no llega la fecha de restablecimiento) / `false` (ya vencidos) | `?vigentes=true` |

### Otros

| Método | Ruta                 | Acceso  | Descripción |
|--------|----------------------|---------|-------------|
| GET    | `/actuator/health`   | Público | Estado de la API. |
| GET    | `/swagger-ui.html`   | Público | Documentación interactiva. |
| GET    | `/v3/api-docs`       | Público | Especificación OpenAPI en JSON. |

Un valor desconocido en un filtro responde 400 con la lista de valores permitidos.

### Seguridad y usuarios

- Los tokens son JWT emitidos por Keycloak (realm `cuidagua`, cliente `cuidagua-app`) y se envían en `Authorization: Bearer <token>`.
- Los roles se leen de `realm_access.roles`: `CIUDADANO`, `PERSONAL` y `ADMIN`.
- **La API nunca guarda contraseñas.** En la primera petición autenticada de cada persona, la API crea su fila en `usuarios` a partir del token (ver [sección 7](#usuarios-y-keycloak)). Los reportes, avisos e historial se relacionan con esa fila (`usuario_id`, `creado_por_id`, `responsable_id`).

### Campos de `POST /api/reportes`

| Campo         | Tipo    | Obligatorio | Reglas |
|---------------|---------|-------------|--------|
| `categoria`   | texto   | Sí | valor del catálogo de categorías |
| `descripcion` | texto   | Sí | 10 a 500 caracteres |
| `zonaId`      | número  | Sí | id existente de `GET /api/zonas` (si no existe: 400) |
| `latitud`     | número  | No | entre -90 y 90, hasta 8 decimales; se envía junto con `longitud` |
| `longitud`    | número  | No | entre -180 y 180, hasta 8 decimales; se envía junto con `latitud` |
| `evidencias`  | lista de textos | No | máx. 5 URLs válidas de hasta 255 caracteres (tabla `evidencias`) |

El servidor asigna el **folio** (`CA-<año>-<consecutivo>`, ej. `CA-2026-000001`), el estado `pendiente`, las fechas y el usuario del token. También guarda la primera fila del historial (`null → pendiente`). Los textos se guardan sin espacios al inicio ni al final.

### Cambio de estado: `PATCH /api/reportes/{id}/estado`

```json
{ "estado": "en_revision", "observacion": "Cuadrilla asignada" }
```

| Campo         | Obligatorio | Reglas |
|---------------|-------------|--------|
| `estado`      | Sí | nuevo estado |
| `observacion` | Solo al pasar a `rechazado` | máx. 500 caracteres |

Flujo permitido:

```
pendiente ──► en_revision ──► resuelto
    │              │
    ├──► resuelto  └──► rechazado
    └──► rechazado
```

`resuelto` y `rechazado` son finales. Una transición no permitida (o al mismo estado) responde **409**. Cada cambio válido actualiza `reportes.estado` y `fecha_actualizacion` y agrega una fila a `historial_estados` con el estado anterior, el nuevo, la observación y el responsable.

### Respuesta de `GET /api/reportes/{id}/historial`

```json
{
  "exito": true,
  "mensaje": "Se encontraron 2 cambios de estado",
  "datos": [
    { "id": 1, "estadoAnterior": null, "estadoNuevo": "pendiente", "observacion": "Reporte registrado",
      "responsable": "Carla Ciudadana", "fecha": "2026-11-20T10:15:30.123456" },
    { "id": 2, "estadoAnterior": "pendiente", "estadoNuevo": "en_revision", "observacion": "Cuadrilla asignada",
      "responsable": "Pedro Personal", "fecha": "2026-11-20T11:00:00.654321" }
  ]
}
```

### Respuesta de `GET /api/reportes/resumen`

```json
{
  "exito": true,
  "mensaje": "Resumen de reportes",
  "datos": {
    "total": 3,
    "porEstado": { "pendiente": 2, "en_revision": 1, "resuelto": 0, "rechazado": 0 },
    "porCategoria": { "fuga": 3, "tuberia_danada": 0, "falta_suministro": 0, "baja_presion": 0, "otro": 0 }
  }
}
```

### Campos de `POST /api/avisos`

| Campo                   | Tipo   | Obligatorio | Reglas |
|-------------------------|--------|-------------|--------|
| `titulo`                | texto  | Sí | 5 a 150 caracteres |
| `mensaje`               | texto  | Sí | 10 a 1000 caracteres |
| `zonaId`                | número | No | id de `GET /api/zonas`; sin `zonaId` el aviso es **general** (toda la ciudad) |
| `tipo`                  | texto  | Sí | valor del catálogo de tipos de aviso |
| `fechaInicio`           | fecha  | No | debe ser anterior a `fechaRestablecimiento` |
| `fechaRestablecimiento` | fecha  | Sí | debe estar en el futuro |

Las fechas usan el formato `yyyy-MM-ddTHH:mm:ss` (ej. `2026-11-20T08:00:00`), en hora del centro de México (`TZ=America/Mexico_City`).

### Campo `horario` en las respuestas de avisos

Cada aviso incluye `horario`, un texto en español listo para mostrar en la app. Se calcula con `fechaInicio` y `fechaRestablecimiento` cada vez que se responde, así que no se guarda en la base de datos ni se envía al crear o editar un aviso.

| `fechaInicio` | `fechaRestablecimiento` | `horario` |
|---------------|-------------------------|-----------|
| `2026-11-25T08:00:00` | `2026-11-25T18:00:00` | `Del 25 nov 08:00 al 25 nov 18:00` |
| `null` | `2026-11-25T18:00:00` | `Hasta el 25 nov 18:00` |
| `2026-12-30T08:00:00` | `2027-01-02T18:30:00` | `Del 30 dic 08:00 al 2 ene 2027 18:30` (el año solo aparece si no es el actual) |

---

## 5. Formato de respuestas

Todas las respuestas tienen la misma forma, para que Flutter las procese igual:

- **Éxito:** `{ "exito": true, "mensaje": "...", "datos": ... }`
- **Error:** `{ "exito": false, "mensaje": "...", "errores": { "campo": "motivo" } }`

| Código | Cuándo |
|--------|--------|
| 201 | Se creó un reporte o aviso |
| 200 | Consulta, cambio de estado, edición o eliminación correctos |
| 400 | Datos inválidos (validación, JSON mal formado, zona inexistente o filtro con valor desconocido) |
| 401 | No se envió token, o es inválido o expiró |
| 403 | El token es válido pero el usuario no tiene el rol necesario |
| 404 | No existe el reporte o aviso con ese `id` |
| 409 | El cambio de estado no está permitido, o el correo del token ya pertenece a otra cuenta |

### 201 – Reporte creado

```json
{
  "exito": true,
  "mensaje": "Reporte registrado con folio CA-2026-000001",
  "datos": {
    "id": 1,
    "folio": "CA-2026-000001",
    "categoria": "fuga",
    "descripcion": "Fuga de agua en la banqueta frente al número 25",
    "zona": { "id": 2, "nombre": "Zona Centro" },
    "latitud": 20.1765,
    "longitud": -98.0535,
    "estado": "pendiente",
    "usuario": "Carla Ciudadana",
    "evidencias": [
      { "id": 1, "url": "https://ejemplo.com/fotos/fuga1.jpg", "fechaCarga": "2026-11-20T10:15:30.123456" }
    ],
    "fechaCreacion": "2026-11-20T10:15:30.123456",
    "fechaActualizacion": "2026-11-20T10:15:30.123456"
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
    "zona": { "id": 1, "nombre": "Zona Norte" },
    "tipo": "corte",
    "fechaInicio": null,
    "fechaRestablecimiento": "2026-11-22T08:00:00",
    "horario": "Hasta el 22 nov 08:00",
    "vigente": true,
    "creadoPor": "Andrés Administrador",
    "fechaPublicacion": "2026-11-20T10:20:00.654321",
    "fechaActualizacion": null
  }
}
```

### 400 – Error de validación

```json
{
  "exito": false,
  "mensaje": "Los datos enviados no son válidos",
  "errores": {
    "categoria": "La categoría es obligatoria",
    "descripcion": "La descripción debe tener entre 10 y 500 caracteres",
    "zonaId": "La zona es obligatoria",
    "latitud": "La latitud debe estar entre -90 y 90"
  }
}
```

Con un valor desconocido:

```json
{
  "exito": false,
  "mensaje": "Los datos enviados no son válidos",
  "errores": {
    "categoria": "Valor no válido. Valores permitidos: fuga, tuberia_danada, falta_suministro, baja_presion, otro"
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
    "estado": "El reporte está en estado resuelto y ya no puede cambiar"
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

La colección pide los tokens de los tres usuarios, los guarda y verifica cada caso:

- **Zonas:** listado del catálogo.
- **Reportes:** crear válido con evidencias (201, con folio), inválido (400), zona inexistente (400), sin token (401); listados y filtros por estado/categoría/zona (200); filtro inválido (400); detalle (200) e inexistente (404); mis reportes; cambio de estado como ciudadano (403), como personal (200), transición no permitida (409), rechazo sin observación (400); historial; resumen del panel.
- **Avisos:** crear como admin (201), como personal (403), con fecha pasada (400); listados y filtro de vigentes por zona/tipo; detalle; editar (200); eliminar como ciudadano (403) y como admin (200); detalle de aviso eliminado (404).

Las peticiones guardan los ids creados en las variables `reporteId` y `avisoId`, por eso se ejecutan en orden.

### Opción B: Thunder Client o Postman

1. Abre **Thunder Client** en la barra lateral → **Collections** → menú **≡** → **Import** y elige `backend/pruebas/CuidAgua-API.postman_collection.json`. En Postman: **Import** con el mismo archivo.
2. Ejecuta primero **1. Autenticación** (los tres tokens) y luego los demás en orden.
3. Los scripts guardan los tokens en las variables `tokenCiudadano`, `tokenPersonal` y `tokenAdmin`. Si tu versión de Thunder Client no ejecuta scripts, copia el `access_token` de la respuesta y pégalo en la variable de la colección.

### Opción C: curl

```bash
# 1. Obtener token de ciudadano1
TOKEN=$(curl -s -X POST http://localhost:8180/realms/cuidagua/protocol/openid-connect/token \
  -d grant_type=password -d client_id=cuidagua-app \
  -d username=ciudadano1 -d password=ciudadano123 | sed -E 's/.*"access_token":"([^"]+)".*/\1/')

# 2. Ver las zonas
curl -s http://localhost:8080/api/zonas

# 3. Crear un reporte
curl -i -X POST http://localhost:8080/api/reportes \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"categoria":"fuga","descripcion":"Fuga de agua frente al número 25","zonaId":2,"latitud":20.1765,"longitud":-98.0535}'

# 4. Listar reportes pendientes de fugas en una zona
curl -s "http://localhost:8080/api/reportes?estado=pendiente&categoria=fuga&zonaId=2"

# 5. Cambiar el estado (requiere token de personal1 o admin1 en $TOKEN_PERSONAL)
curl -s -X PATCH http://localhost:8080/api/reportes/1/estado \
  -H "Authorization: Bearer $TOKEN_PERSONAL" -H "Content-Type: application/json" \
  -d '{"estado":"en_revision","observacion":"Cuadrilla asignada"}'
```

Para los otros tokens usa `username=personal1` / `password=personal123` o `username=admin1` / `password=admin123`.

---

## 7. Base de datos

### Migraciones

| Archivo | Contenido |
|---------|-----------|
| `V1__esquema_base_de_datos.sql` | Script oficial del rol de base de datos **sin cambios**: tablas `usuarios`, `zonas`, `reportes`, `evidencias`, `historial_estados`, `asignaciones` y `avisos`, sus índices y el catálogo de zonas (Zona Norte, Zona Centro, Zona Sur). No incluye los datos de prueba con `credencial_hash` ni los registros que dependen de ellos. |
| `V2__ajustes_api.sql` | Ajustes acordados: `usuarios.keycloak_id`; en `avisos`, las columnas `tipo`, `fecha_inicio`, `fecha_restablecimiento`, `creado_por_id` y `fecha_actualizacion`; restricciones CHECK de estados, categorías, tipos y coordenadas; la secuencia `folio_reportes_seq`; índices para los filtros. |

**No modifiques una migración que ya se ejecutó.** Para cambios nuevos crea `V3__descripcion.sql`, `V4__...` y avisa al rol de base de datos para que su script se mantenga igual al backend.

### Usuarios y Keycloak

El inicio de sesión lo hace Keycloak. La tabla `usuarios` del diseño oficial se usa como **registro local** de cada persona, sin contraseñas:

1. En cada petición autenticada que lo necesita (crear reporte, cambiar estado, publicar aviso), `UsuarioService` busca al usuario por `keycloak_id` (claim `sub` del token).
2. Si no existe, lo crea con `nombre` (claim `name`), `correo` (claim `email`, en minúsculas) y `rol` (ADMIN → `administrador`, PERSONAL → `personal`, otro → `ciudadano`). En `credencial_hash` guarda el texto fijo **`KEYCLOAK`**, que solo indica que la autenticación es externa (la columna es `NOT NULL` en el diseño oficial).
3. Si ya existe, actualiza nombre, correo y rol, porque Keycloak es la fuente de verdad.
4. Si hay una fila con el mismo correo **sin** `keycloak_id` (por ejemplo, dada de alta desde un script), la vincula solo si Keycloak marca el correo como verificado (`email_verified`). Si el correo pertenece a otra cuenta, responde 409.

### Reiniciar la base de datos de desarrollo

Las migraciones cambiaron por completo respecto a versiones anteriores del backend, así que una base que ya tenía las migraciones viejas **no arranca** (Flyway detecta que V1 y V2 son distintas). Hay que vaciarla. **Se pierden los datos de desarrollo.**

**Opción 1: borrar el esquema desde la terminal del Codespace** (no requiere Docker):

```bash
# Detén la API si está corriendo (Ctrl+C) y ejecuta:
PGPASSWORD=cuidagua psql -h localhost -U cuidagua -d cuidagua \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
mvn spring-boot:run   # Flyway vuelve a crear todo con V1 y V2
```

Si `psql` no está instalado en el contenedor `app`, usa el del contenedor de la base: en VS Code abre la pestaña **Docker** (o una terminal en la máquina anfitriona) y ejecuta `docker exec -it <contenedor-db> psql -U cuidagua -d cuidagua -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"`.

**Opción 2: recrear los contenedores con un volumen nuevo** (desde la máquina anfitriona o fuera del Codespace, en la carpeta `backend`):

```bash
docker compose -f docker-compose.dev.yml down -v   # -v borra el volumen cuidagua_dev_pgdata
docker compose -f docker-compose.dev.yml up -d
```

En Codespaces, lo equivalente es **Rebuild Container** desde la paleta de comandos, aunque el volumen puede conservarse. Si después de reconstruir sigue el error, usa la opción 1.

**Keycloak (nuevo rol `PERSONAL` y usuario `personal1`):** Keycloak solo importa el realm cuando no existe. Como guarda sus datos dentro de su contenedor (sin volumen), **recrear** el contenedor (`down` + `up`, o *Rebuild Container*) vuelve a importar `realm-cuidagua.json`. Un simple reinicio (`restart`) no basta. También puedes crear el rol y el usuario a mano en la consola `http://localhost:8180` (`admin` / `admin`).

---

## 8. Notas para el equipo

- **Issuer del token:** la API acepta los issuers de `KEYCLOAK_ISSUERS` (ver [sección 9](#9-validación-del-token-desde-emulador-o-celular)). Si la app se conecta por la URL pública de un Codespace, agrega esa URL a la lista.
- **docker-compose.yml de la raíz:** sigue usando `postgres:17` y `cuidagua_db`, y en `develop` monta `database/cuidagua_db.sql` para crear las tablas. El backend (`docker-compose.yml` y `docker-compose.dev.yml` de esta carpeta) usa PostgreSQL 16 con la base `cuidagua` y **las tablas las crea solo Flyway**. Si la API apunta a una base ya creada con el script, Flyway falla porque el esquema no está vacío. Conviene unificarlos cuando se cierren las decisiones pendientes de `docs/DECISIONES_TECNICAS.md`.
- **Cambios para la app Flutter (respecto a la versión anterior de la API):**
  - Los ids son enteros (`SERIAL`) y los valores de catálogo van en minúsculas (`pendiente`, `fuga`, `corte`…). El estado `EN_PROCESO` pasa a ser `en_revision`.
  - Reportes: `tipo` → `categoria` (`TUBERIA_ROTA` → `tuberia_danada`, `SIN_AGUA` → `falta_suministro`); `zona` (texto) → `zonaId` (y en la respuesta, `zona: {id, nombre}`); se eliminan `direccion` y `colonia`; `fotoUrl` → `evidencias` (lista); nuevo campo `folio`. `comentario` → `observacion` en el cambio de estado; `comentarioEstado` y `actualizadoPor` se sustituyen por `GET /api/reportes/{id}/historial`. En el resumen, `porTipo` → `porCategoria`.
  - Avisos: `zona` → `zonaId` (opcional); se elimina `colonia`; `fechaCreacion` → `fechaPublicacion`; el título admite hasta 150 caracteres.
- **Tabla `asignaciones`:** está mapeada (`Asignacion`) pero todavía no tiene endpoints.
- **Swagger en producción:** desactívalo con `springdoc.api-docs.enabled=false` y `springdoc.swagger-ui.enabled=false`.

---

## 9. Validación del token desde emulador o celular

Keycloak escribe en el token (claim `iss`, *issuer*) **la dirección con la que se le pidió el token**. Esa dirección cambia según dónde corre la app:

| Dónde corre la app | Keycloak se llama en | `iss` del token |
|--------------------|----------------------|-----------------|
| Navegador, curl o Postman en la PC | `http://localhost:8180` | `http://localhost:8180/realms/cuidagua` |
| Emulador de Android | `http://10.0.2.2:8180` (`10.0.2.2` es la PC vista desde el emulador) | `http://10.0.2.2:8180/realms/cuidagua` |
| Celular en la misma red Wi-Fi | `http://<IP de la PC>:8180` | `http://192.168.1.50:8180/realms/cuidagua` (ejemplo) |

Por eso la API no usa un solo issuer fijo. `config/KeycloakJwtConfig.java` valida cada token así:

1. **Firma:** descarga las llaves públicas de Keycloak desde `KEYCLOAK_JWK_SET_URI`. Dentro de Docker usa la red interna (`http://keycloak:8180/...`), que no depende de cómo se conecte la app.
2. **Issuer:** el `iss` del token debe ser uno de los de `KEYCLOAK_ISSUERS` (separados por comas). Si no está, la respuesta es **401**.
3. **Expiración:** el token no debe haber vencido. Dura 30 minutos (`accessTokenLifespan` del realm).

| Variable | Para qué sirve | En `docker-compose.yml` |
|----------|----------------|-------------------------|
| `KEYCLOAK_ISSUERS` | Issuers aceptados | `localhost`, `127.0.0.1`, `10.0.2.2` e `IP_LAN` (puerto 8180) |
| `KEYCLOAK_JWK_SET_URI` | Dirección de las llaves públicas | `http://keycloak:8180/realms/cuidagua/protocol/openid-connect/certs` |
| `KEYCLOAK_ISSUER_URI` | Valor por defecto de las dos anteriores (compatibilidad con el Dev Container) | — |
| `IP_LAN` | IP de la PC en la red local; se agrega a `KEYCLOAK_ISSUERS` | Se lee de `backend/.env` |

Al arrancar, la API escribe en el log qué issuers acepta:

```
Tokens aceptados de los issuers [http://localhost:8180/realms/cuidagua, ..., http://192.168.1.50:8180/realms/cuidagua] (llaves en http://keycloak:8180/...)
```

**Del lado de Keycloak** no hace falta configurar nada: sin `KC_HOSTNAME`, en modo desarrollo usa como issuer la dirección de cada petición. El realm tiene `sslRequired: none`, así que acepta HTTP desde la red local (solo para desarrollo).

**Alternativa con issuer fijo:** si prefieres que todos los tokens tengan el mismo `iss`, define `KC_HOSTNAME=http://<IP de la PC>:8180` en el servicio `keycloak` y deja `KEYCLOAK_ISSUERS` con solo esa dirección. Si la IP de la PC cambia (otra red Wi-Fi), hay que actualizarla.

---

## 10. Para el equipo de Flutter

### Levantar el backend con un solo comando

Solo necesitas **Docker Desktop** (no hace falta Java, Maven ni PostgreSQL instalados).

```bash
cd backend
docker compose up --build
```

La primera vez tarda unos minutos (descarga las imágenes y compila la API). Está lista cuando el log muestra `Started CuidaguaApiApplication`. Compruébalo:

```bash
curl http://localhost:8080/actuator/health     # {"status":"UP"}
```

| Servicio   | Dirección en la PC | Notas |
|------------|--------------------|-------|
| API        | `http://localhost:8080/api` | Swagger: `http://localhost:8080/swagger-ui.html` |
| Keycloak   | `http://localhost:8180` | Consola de administración: `admin` / `admin` |
| PostgreSQL | `localhost:5432` | Base `cuidagua`, usuario `cuidagua`, contraseña `cuidagua` |

Para apagar todo: `Ctrl+C` y luego `docker compose down`. Los datos de PostgreSQL se conservan; `docker compose down -v` los borra. Las tablas las crea Flyway al arrancar la API, y las tres zonas (Zona Norte, Zona Centro, Zona Sur) ya vienen cargadas.

> No lo levantes al mismo tiempo que el Dev Container del backend ni que el `docker-compose.yml` de la raíz: usan los mismos puertos (5432, 8080 y 8180).

### Usuarios de prueba

| Usuario      | Contraseña     | Rol en `GET /api/usuarios/me` | Qué puede hacer |
|--------------|----------------|-------------------------------|-----------------|
| `ciudadano1` | `ciudadano123` | `ciudadano`     | Crear reportes, ver los suyos |
| `personal1`  | `personal123`  | `personal`      | Lo anterior + cambiar el estado de los reportes y ver el resumen |
| `admin1`     | `admin123`     | `administrador` | Lo anterior + publicar, editar y eliminar avisos |

También se puede iniciar sesión con el correo (`ciudadano1@cuidagua.local`, etc.) en lugar del usuario.

### URL base según dónde corre la app

| Dónde corre la app | API (`baseUrl`) | Keycloak |
|--------------------|-----------------|----------|
| Flutter web / escritorio en la misma PC | `http://localhost:8080/api` | `http://localhost:8180` |
| Emulador de Android | `http://10.0.2.2:8080/api` | `http://10.0.2.2:8180` |
| Celular físico en la misma red Wi-Fi | `http://<IP de la PC>:8080/api` | `http://<IP de la PC>:8180` |

**Para el celular**, la PC que corre Docker debe hacer lo siguiente:

1. Buscar su IP: en Windows, `ipconfig` → "Dirección IPv4" del adaptador Wi-Fi (ej. `192.168.1.50`).
2. Copiar `backend/.env.example` como `backend/.env` y escribir `IP_LAN=192.168.1.50`.
3. Aplicar el cambio: `docker compose up -d` (recrea la API con la nueva lista de issuers).
4. Si el celular no conecta, permitir los puertos 8080 y 8180 en el Firewall de Windows (aparece un aviso la primera vez) y comprobar que la red Wi-Fi no aísle a los dispositivos (las redes de invitados suelen hacerlo).
5. Probar desde el navegador del celular: `http://192.168.1.50:8080/api/zonas`.

> **Android y HTTP:** desde Android 9, las apps bloquean `http://` por defecto. Para desarrollo agrega `android:usesCleartextTraffic="true"` en la etiqueta `<application>` de `android/app/src/main/AndroidManifest.xml`.

### Iniciar sesión: pedir el token a Keycloak

La API **no tiene** un endpoint de login: la app pide el token directamente a Keycloak con el usuario y la contraseña, y después lo manda en cada petición protegida.

```http
POST {keycloak}/realms/cuidagua/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&client_id=cuidagua-app&username=ciudadano1&password=ciudadano123
```

Respuesta (resumida):

```json
{ "access_token": "eyJhbGciOi...", "expires_in": 1800, "refresh_token": "eyJhbGciOi...", "token_type": "Bearer" }
```

Ejemplo con el paquete `http` (ya está en `pubspec.yaml`):

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// Emulador de Android. En la PC usa localhost; en un celular, la IP de la PC.
const keycloakUrl = 'http://10.0.2.2:8180';
const apiUrl = 'http://10.0.2.2:8080/api';

/// Pide el token a Keycloak. Devuelve null si el usuario o la contraseña son incorrectos.
Future<String?> iniciarSesion(String usuario, String contrasena) async {
  final respuesta = await http.post(
    Uri.parse('$keycloakUrl/realms/cuidagua/protocol/openid-connect/token'),
    // Un Map en body se envía como application/x-www-form-urlencoded.
    body: {
      'grant_type': 'password',
      'client_id': 'cuidagua-app',
      'username': usuario,
      'password': contrasena,
    },
  );
  if (respuesta.statusCode != 200) return null; // 401: credenciales inválidas
  return jsonDecode(respuesta.body)['access_token'] as String;
}

/// Datos del usuario que inició sesión: {id, nombre, correo, rol}.
Future<Map<String, dynamic>> miPerfil(String token) async {
  final respuesta = await http.get(
    Uri.parse('$apiUrl/usuarios/me'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );
  final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
  if (cuerpo['exito'] != true) throw Exception(cuerpo['mensaje']);
  return cuerpo['datos'] as Map<String, dynamic>; // rol: ciudadano | personal | administrador
}
```

Flujo recomendado:

1. Pantalla de login → `iniciarSesion(usuario, contrasena)`. Ya no hace falta que la persona elija su rol.
2. Con el token → `GET /api/usuarios/me`. Según `rol`, mostrar las pantallas de ciudadano o de administrador (`personal` también puede gestionar reportes).
3. En cada petición protegida, enviar `Authorization: Bearer <token>`.
4. El token dura **30 minutos**. Si la API responde **401**, volver a pedir el token (o renovarlo con `grant_type=refresh_token` y el `refresh_token`).

### Lo que hay que saber de las respuestas

- Todas tienen la forma `{ "exito", "mensaje", "datos" }`. Las listas vienen en `datos`, no en la raíz: `jsonDecode(body)['datos'] as List`.
- Una lista vacía responde **200** con `"datos": []`, no 404.
- Los catálogos van en minúsculas con guion bajo (`en_revision`, `falta_suministro`, `baja_presion`). La tabla de valores está en la [sección 4](#4-endpoints).
- Las zonas salen de `GET /api/zonas`. Usa su `id` como `zonaId` al crear reportes y avisos.
- Los avisos traen `horario` listo para mostrar (ej. `"Del 25 nov 08:00 al 25 nov 18:00"`).
- Códigos que conviene manejar: 400 (datos inválidos, con `errores` por campo), 401 (falta el token o venció), 403 (sin permiso), 404 (no existe) y 409 (cambio de estado no permitido).
