# CuidAgua
CuidAgua es una aplicación móvil de impacto social enfocada en la población general de México. Su objetivo principal es ayudar a los ciudadanos a reportar fugas de agua y problemas en tuberías, además de brindar un sistema de notificaciones proactivas que avisa a los usuarios un día antes de que se restablezca el suministro de agua en su zona.

Características Principales (Sprint 1 & 2)

Reportes Ciudadanos: Interfaz intuitiva para que los usuarios puedan reportar fugas de agua y averías en tuberías o servicios hídricos de su comunidad.

Alertas de Suministro: Sistema de notificaciones previas que alerta a los ciudadanos sobre los días y horas en las que "caerá" agua, permitiendo una mejor planeación ante el suministro irregular.

Stack Tecnológico

El proyecto está dividido en un entorno de trabajo colaborativo (Monorepositorio) soportado por la siguiente tecnología:

Frontend (Aplicación Móvil)

Framework: Flutter & Dart.

Arquitectura: Clean Architecture (separación estricta en capas: Dominio, Datos y Presentación).

Gestión de Datos: Programación Asíncrona nativa (Future, async, await) para peticiones HTTP sin bloquear la UI.

Backend & Infraestructura

API REST: Node.js / Python (En desarrollo).

Base de Datos: PostgreSQL para el almacenamiento seguro de usuarios y reportes ciudadanos.

Contenedores: Docker y Docker Compose ejecutándose sobre WSL 2 (Windows Subsystem for Linux) para garantizar la paridad entre desarrollo y producción.


Estructura del Repositorio

cuidagua/
├── frontend/            # Código fuente de la App en Flutter
├── backend/             # Código de la API REST 
├── docker-compose.yml   # Orquestación para PostgreSQL y el servidor backend
├── .gitignore           # Exclusión de compilaciones, contenedores y .env
└── README.md            # Documentación principal

Metodología de Trabajo y Equipo

Este proyecto es desarrollado por un equipo de 5 personas utilizando Scrum con Sprints de 2 semanas. Los roles están distribuidos de la siguiente manera:

Scrum Master / DevOps: Orquestación de Docker, gestión de GitHub Flow y ceremonias Scrum.

Ingeniero de Datos: Gestión y modelado de PostgreSQL.

Desarrollador Backend: Creación de endpoints de la API para reportes y notificaciones.

Desarrollador Frontend (UI): Construcción de vistas en Flutter bajo Clean Architecture.

Desarrollador Frontend (Asíncrono): Integración de lógicas asíncronas y consumo de la API.

Flujo de Ramas (GitHub Flow)

main: Código de producción, 100% estable.

develop: Rama principal de integración para el Sprint en curso.

feature/*: Ramas de características (Ej. feature/reporte-fugas, feature/notificaciones-agua).

Configuración del Entorno Local

Clona este repositorio dentro de tu entorno WSL 2:

git clone https://github.com/tu-usuario/cuidagua.git


Levanta los servicios de Backend (Base de datos y API):

docker-compose up -d


Navega al directorio del frontend y obtén las dependencias de Flutter:

cd frontend
flutter pub get


Ejecuta la aplicación en tu emulador o dispositivo físico:

flutter run
