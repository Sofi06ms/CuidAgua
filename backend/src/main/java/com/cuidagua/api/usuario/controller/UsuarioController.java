package com.cuidagua.api.usuario.controller;

import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.config.OpenApiConfig;
import com.cuidagua.api.usuario.dto.UsuarioResponse;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.service.UsuarioService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Datos del usuario que inició sesión. Todas las rutas requieren token (SecurityConfig). */
@Tag(name = "Usuarios", description = "Perfil del usuario autenticado con Keycloak")
@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @Operation(summary = "Mi perfil",
            description = """
                    Requiere token (cualquier rol). Devuelve id, nombre, correo y rol del usuario del token.
                    Si es la primera petición de esa persona, crea su fila en la tabla usuarios; \
                    si ya existe, actualiza nombre, correo y rol con lo que diga Keycloak.
                    La app puede llamarlo justo después de iniciar sesión para saber qué pantallas mostrar \
                    (rol ciudadano, personal o administrador).""")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UsuarioResponse>> me(@AuthenticationPrincipal Jwt jwt) {
        UsuarioResponse usuario = UsuarioResponse.desde(usuarioService.sincronizar(UsuarioToken.desde(jwt)));
        return ResponseEntity.ok(ApiResponse.ok("Usuario autenticado", usuario));
    }
}
