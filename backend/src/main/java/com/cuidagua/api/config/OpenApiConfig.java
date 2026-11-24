package com.cuidagua.api.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

/**
 * Documentación OpenAPI. Swagger UI: http://localhost:8080/swagger-ui.html
 * <p>
 * Para probar rutas protegidas, pulsa "Authorize" y pega el access_token de Keycloak.
 */
@Configuration
@OpenAPIDefinition(info = @Info(
        title = "CuidAgua API",
        version = "0.2.0",
        description = """
                Reportes ciudadanos de incidencias de agua y avisos de suministro.
                Todas las respuestas usan el formato { exito, mensaje, datos, errores }.
                Estados, categorías y tipos usan los valores en minúsculas de la base de datos                 (ej. "pendiente", "tuberia_danada", "corte").
                Roles de Keycloak: CIUDADANO, PERSONAL y ADMIN."""))
@SecurityScheme(
        name = OpenApiConfig.BEARER,
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        description = "Token de Keycloak (realm cuidagua, cliente cuidagua-app)")
public class OpenApiConfig {

    /** Nombre del esquema de seguridad para usar en @SecurityRequirement. */
    public static final String BEARER = "bearer-jwt";
}
