package com.cuidagua.api.usuario.dto;

import com.cuidagua.api.usuario.entity.RolUsuario;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.Collection;
import java.util.Locale;
import java.util.Map;

/**
 * Datos del usuario que vienen en el token de Keycloak.
 *
 * @param keycloakId       claim "sub"
 * @param nombre           claim "name"; si no viene, "preferred_username"
 * @param correo           claim "email" en minúsculas; si no viene, uno interno derivado del "sub"
 * @param correoVerificado claim "email_verified"
 * @param rol              ADMIN -> administrador, PERSONAL -> personal, otro -> ciudadano
 */
public record UsuarioToken(String keycloakId, String nombre, String correo, boolean correoVerificado, RolUsuario rol) {

    /** Dominio para usuarios cuyo token no trae correo (la columna correo es NOT NULL y UNIQUE). */
    static final String DOMINIO_SIN_CORREO = "@sin-correo.cuidagua.local";

    public static UsuarioToken desde(Jwt jwt) {
        String sub = jwt.getSubject();

        String nombre = primeroNoVacio(jwt.getClaimAsString("name"), jwt.getClaimAsString("preferred_username"), sub);

        String email = jwt.getClaimAsString("email");
        String correo = email == null || email.isBlank()
                ? sub + DOMINIO_SIN_CORREO
                : email.trim().toLowerCase(Locale.ROOT);

        return new UsuarioToken(sub, recortar(nombre, 100), recortar(correo, 150),
                Boolean.TRUE.equals(jwt.getClaimAsBoolean("email_verified")), rol(jwt));
    }

    private static RolUsuario rol(Jwt jwt) {
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        if (realmAccess == null || !(realmAccess.get("roles") instanceof Collection<?> roles)) {
            return RolUsuario.CIUDADANO;
        }
        if (roles.contains("ADMIN")) {
            return RolUsuario.ADMINISTRADOR;
        }
        if (roles.contains("PERSONAL")) {
            return RolUsuario.PERSONAL;
        }
        return RolUsuario.CIUDADANO;
    }

    private static String primeroNoVacio(String... valores) {
        for (String valor : valores) {
            if (valor != null && !valor.isBlank()) {
                return valor.trim();
            }
        }
        return null;
    }

    private static String recortar(String valor, int max) {
        return valor.length() <= max ? valor : valor.substring(0, max);
    }
}
