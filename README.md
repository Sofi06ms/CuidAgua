# CuidAgua



Sistema inteligente de reportes de incidencias de agua.



CuidAgua es una aplicación tecnológica de impacto social enfocada en la población de México. Su objetivo es facilitar a los ciudadanos el reporte de fugas de agua, daños en tuberías y otras incidencias relacionadas con el suministro hídrico.



Además, busca mejorar la comunicación entre los ciudadanos y las autoridades mediante notificaciones sobre los horarios y la disponibilidad del suministro de agua en sus zonas.



\## Características principales



\- \*\*Reportes ciudadanos:\*\* permite registrar fugas de agua, averías en tuberías y otros problemas relacionados con el servicio.

\- \*\*Notificaciones de suministro:\*\* informa a los usuarios sobre los horarios y fechas de suministro de agua en su zona.

\- \*\*Identificación de zonas:\*\* combina mecanismos de identificación para determinar la ubicación de los reportes y la zona de suministro.

\- \*\*Panel administrativo web:\*\* permite gestionar la información de reportes e incidencias.

\- \*\*Gestión de incidencias:\*\* facilita el seguimiento de los problemas reportados por los ciudadanos.



\## Stack tecnológico



El proyecto utiliza una arquitectura cliente-servidor y un repositorio centralizado para facilitar el desarrollo colaborativo.



\### Frontend móvil



\- \*\*Framework:\*\* Flutter.

\- \*\*Lenguaje:\*\* Dart.

\- \*\*Arquitectura:\*\* Clean Architecture, organizada en las capas de Dominio, Datos y Presentación.

\- \*\*Programación asíncrona:\*\* Future, async y await para el consumo de servicios y API REST.



\### Backend



\- \*\*Lenguaje:\*\* Java.

\- \*\*Framework:\*\* Spring Boot.

\- \*\*Arquitectura:\*\* arquitectura por capas y patrón Repository.

\- \*\*Comunicación:\*\* API REST.



\### Panel administrativo



\- \*\*Plataforma:\*\* aplicación web.

\- \*\*Objetivo:\*\* administración y seguimiento de reportes e incidencias.



\### Base de datos e infraestructura



\- \*\*Base de datos:\*\* PostgreSQL 17.

\- \*\*Contenedores:\*\* Docker.

\- \*\*Orquestación:\*\* Docker Compose.

\- \*\*Control de versiones:\*\* Git y GitHub.



\## Decisiones técnicas del proyecto



\- El panel administrativo se desarrollará como una aplicación web.

\- La identificación de zonas utilizará un enfoque combinado.

\- Los horarios de suministro de agua serán administrados manualmente.

\- La aplicación móvil se comunicará con el backend mediante una API REST.

\- PostgreSQL almacenará la información de usuarios, reportes y datos relacionados con el suministro.



\## Estructura del repositorio



La estructura inicial del repositorio es la siguiente:



```text

CuidAgua/

├── .gitignore

├── .env.example

├── CONTRIBUTING.md

├── README.md

├── docker-compose.yml

├── database/

├── docs/

│   └── DECISIONES\_TECNICAS.md

└── scripts/

```



Conforme avance el desarrollo, se incorporarán los directorios correspondientes al frontend móvil, backend y panel administrativo.



\## Metodología de trabajo



El proyecto se desarrolla utilizando Scrum, con Sprints de dos semanas y un equipo de cinco integrantes.



Los roles están distribuidos de la siguiente manera:



\- \*\*Scrum Master / DevOps:\*\* administración del repositorio, infraestructura Docker, integración de componentes y coordinación de las actividades Scrum.

\- \*\*Ingeniero de Datos:\*\* diseño, modelado y administración de la base de datos PostgreSQL.

\- \*\*Desarrollador Backend:\*\* implementación de la API REST con Java y Spring Boot.

\- \*\*Desarrollador Frontend (UI):\*\* desarrollo de las interfaces móviles en Flutter bajo Clean Architecture.

\- \*\*Desarrollador de Integraciones Asíncronas:\*\* implementación de la programación asíncrona en Dart e integración con la API REST.



\## Flujo de trabajo con Git



Se utilizan las siguientes ramas:



\- `main`: contiene las versiones estables del proyecto.

\- `develop`: rama de integración para el desarrollo del proyecto.

\- `feature/\*`: ramas destinadas a nuevas funcionalidades.

\- `fix/\*`: ramas destinadas a la corrección de errores.

\- `docs/\*`: ramas destinadas a cambios en la documentación.



Los cambios deben realizarse en ramas de trabajo y posteriormente integrarse mediante Pull Requests hacia `develop`.



\## Configuración del entorno local



\### Requisitos previos



Antes de comenzar, es necesario contar con:



\- Git.

\- Docker Desktop con Docker Compose.

\- Java y Maven (para el desarrollo del backend, cuando esté disponible).

\- Flutter y Dart (para el desarrollo de la aplicación móvil).



En Windows se recomienda utilizar Docker Desktop con integración WSL 2.



\### 1. Clonar el repositorio



```bash

git clone https://github.com/Sofi06ms/CuidAgua.git

cd CuidAgua

```



\### 2. Crear el archivo de variables de entorno



Copiar el archivo de ejemplo:



```bash

cp .env.example .env

```



En Windows también se puede realizar esta copia manualmente.



Abrir el archivo `.env` y configurar una contraseña segura para PostgreSQL. Este archivo contiene información privada y no debe subirse al repositorio.



\*\*Importante:\*\* nunca compartir ni publicar el contenido del archivo `.env`.



\### 3. Levantar PostgreSQL con Docker Compose



Ejecutar:



```bash

docker compose up -d

```



Este comando crea e inicia el contenedor de PostgreSQL utilizando la configuración definida en `docker-compose.yml`.



\### 4. Verificar el estado del contenedor



Ejecutar:



```bash

docker compose ps

```



El contenedor `cuidagua\_postgres` debe aparecer con estado `Up (healthy)`.



\### 5. Detener los servicios



Para detener los contenedores sin eliminar los datos almacenados:



```bash

docker compose down

```



Para volver a iniciarlos:



```bash

docker compose up -d

```



\*\*Importante:\*\* no utilizar `docker compose down -v` salvo que se desee eliminar también el volumen de PostgreSQL y, con él, los datos almacenados.



\## Configuración de la base de datos



Los parámetros iniciales de PostgreSQL son:



| Parámetro | Valor |

|---|---|

| Imagen Docker | postgres:17 |

| Base de datos | cuidagua\_db |

| Usuario | cuidagua\_user |

| Puerto | 5432 |

| Contenedor | cuidagua\_postgres |

| Volumen | postgres\_data |



Las credenciales se obtienen del archivo `.env` de cada integrante.



\## Documentación adicional



\- `CONTRIBUTING.md`: normas para contribuir al repositorio.

\- `docs/DECISIONES\_TECNICAS.md`: decisiones técnicas y arquitectónicas del proyecto.

\- `.env.example`: plantilla de variables de entorno necesarias para PostgreSQL.



\---



\*\*CuidAgua — Tecnología al servicio de una mejor gestión del agua.\*\* 💧

