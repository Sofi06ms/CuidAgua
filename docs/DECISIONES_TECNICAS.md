\# Decisiones técnicas del proyecto CuidAgua



\## 1. Información general



\- \*\*Proyecto:\*\* CuidAgua

\- \*\*Tipo:\*\* Aplicación móvil para reportar incidencias relacionadas con el servicio de agua.

\- \*\*Arquitectura:\*\* Cliente-servidor.

\- \*\*Metodología:\*\* Scrum.



\## 2. Tecnologías seleccionadas



| Componente | Tecnología |

|---|---|

| Aplicación móvil | Flutter |

| Backend | Java con Spring Boot |

| Base de datos | PostgreSQL |

| Infraestructura | Docker y Docker Compose |

| Control de versiones | Git y GitHub |

| Panel administrativo | Aplicación web |



\## 3. Decisiones de infraestructura



\- Docker se utilizará para facilitar la ejecución del entorno de desarrollo.

\- PostgreSQL será el sistema gestor de base de datos.

\- Docker Compose permitirá administrar los servicios del entorno.

\- Las variables de entorno se utilizarán para configurar credenciales y conexiones.

\- Los archivos `.env` con información sensible no deberán subirse a GitHub.



\## 4. Organización del repositorio



\- `backend/`: código del servidor Spring Boot.

\- `database/`: scripts y recursos relacionados con PostgreSQL.

\- `docs/`: documentación técnica del proyecto.

\- `scripts/`: comandos y herramientas auxiliares.

\- `docker-compose.yml`: configuración de los servicios en contenedores.



\## 5. Flujo de trabajo Git



\- `main`: versión estable del proyecto.

\- `develop`: rama de integración.

\- `feature/`: nuevas funcionalidades.

\- `fix/`: correcciones.

\- `docs/`: cambios de documentación.



Los cambios se integrarán mediante Pull Requests hacia `develop`.



\## 6. Decisiones pendientes



\- Versión definitiva de Spring Boot.

\- Versión de PostgreSQL.

\- Nombre definitivo de la base de datos.

\- Configuración de conexión entre backend y PostgreSQL.

\- Configuración final de Docker Compose.

