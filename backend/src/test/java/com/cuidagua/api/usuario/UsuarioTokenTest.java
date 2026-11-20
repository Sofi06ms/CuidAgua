package com.cuidagua.api.usuario;

import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.entity.RolUsuario;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/** Lectura de los datos del usuario desde el token de Keycloak. */
class UsuarioTokenTest {

    @Test
    void tomaNombreCorreoYRolDelToken() {
        Jwt jwt = Jwt.withTokenValue("t").header("alg", "none")
                .subject("abc-123")
                .claim("name", "Andrés Administrador")
                .claim("preferred_username", "admin1")
                .claim("email", "  Admin1@CuidAgua.local ")
                .claim("email_verified", true)
                .claim("realm_access", Map.of("roles", List.of("CIUDADANO", "ADMIN")))
                .build();

        UsuarioToken token = UsuarioToken.desde(jwt);

        assertThat(token.keycloakId()).isEqualTo("abc-123");
        assertThat(token.nombre()).isEqualTo("Andrés Administrador");
        assertThat(token.correo()).isEqualTo("admin1@cuidagua.local");
        assertThat(token.correoVerificado()).isTrue();
        assertThat(token.rol()).isEqualTo(RolUsuario.ADMINISTRADOR);
    }

    @Test
    void sinNombreNiCorreoUsaUsernameYUnCorreoInterno() {
        Jwt jwt = Jwt.withTokenValue("t").header("alg", "none")
                .subject("abc-123")
                .claim("preferred_username", "personal1")
                .claim("realm_access", Map.of("roles", List.of("PERSONAL")))
                .build();

        UsuarioToken token = UsuarioToken.desde(jwt);

        assertThat(token.nombre()).isEqualTo("personal1");
        assertThat(token.correo()).isEqualTo("abc-123@sin-correo.cuidagua.local");
        assertThat(token.correoVerificado()).isFalse();
        assertThat(token.rol()).isEqualTo(RolUsuario.PERSONAL);
    }

    @Test
    void sinRolesEsCiudadano() {
        Jwt jwt = Jwt.withTokenValue("t").header("alg", "none").subject("x").build();

        assertThat(UsuarioToken.desde(jwt).rol()).isEqualTo(RolUsuario.CIUDADANO);
    }
}
