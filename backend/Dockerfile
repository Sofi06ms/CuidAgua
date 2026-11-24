# Imagen de la API de CuidAgua. No hace falta tener Java ni Maven instalados.
#
#   docker build -t cuidagua-api .            (desde la carpeta backend)
#
# Normalmente se usa a través de docker-compose.yml: docker compose up --build

# ---------- Etapa 1: compilar con Maven y Java 21 ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Primero solo el pom.xml: así las dependencias quedan en una capa que Docker reutiliza
# mientras no cambie el pom, y recompilar el código es mucho más rápido.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
# Las pruebas se corren aparte (mvn test / mvn verify); aquí solo se empaqueta el .jar.
RUN mvn -B -q package -DskipTests

# ---------- Etapa 2: ejecutar con un JRE 21 ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

# Usuario sin privilegios para no ejecutar la API como root.
RUN groupadd --system cuidagua && useradd --system --gid cuidagua cuidagua

COPY --from=build /build/target/*.jar /app/cuidagua-api.jar

ENV TZ=America/Mexico_City
USER cuidagua
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/cuidagua-api.jar"]
