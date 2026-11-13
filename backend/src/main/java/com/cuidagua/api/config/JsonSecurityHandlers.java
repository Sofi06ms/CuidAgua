package com.cuidagua.api.config;

import com.cuidagua.api.common.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Respuestas JSON para errores de seguridad:
 * 401 (sin token o token inválido) y 403 (sin el rol requerido).
 */
@Component
@RequiredArgsConstructor
public class JsonSecurityHandlers {

    private final ObjectMapper objectMapper;

    public AuthenticationEntryPoint authenticationEntryPoint() {
        return (request, response, authException) -> {
            boolean tokenInvalido = authException instanceof InvalidBearerTokenException;
            String motivo = tokenInvalido
                    ? "El token es inválido o ha expirado"
                    : "No se envió el token de acceso (Authorization: Bearer <token>)";
            response.setHeader("WWW-Authenticate", "Bearer");
            escribir(response, HttpStatus.UNAUTHORIZED,
                    ApiResponse.error("Debes iniciar sesión para realizar esta acción", Map.of("token", motivo)));
        };
    }

    public AccessDeniedHandler accessDeniedHandler() {
        return (request, response, accessDeniedException) -> escribir(response, HttpStatus.FORBIDDEN,
                ApiResponse.error("No tienes permiso para realizar esta acción",
                        Map.of("rol", "Tu usuario no tiene el rol requerido")));
    }

    private void escribir(HttpServletResponse response, HttpStatus status, ApiResponse<Void> cuerpo) throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        objectMapper.writeValue(response.getOutputStream(), cuerpo);
    }
}
