package com.cuidagua.api.common.util;

import org.springframework.security.oauth2.jwt.Jwt;

/** Lectura de datos del usuario desde el token de Keycloak. */
public final class JwtUtils {

    private JwtUtils() {
    }

    /** preferred_username del token; si no viene, el "sub". */
    public static String nombreUsuario(Jwt jwt) {
        String nombre = jwt.getClaimAsString("preferred_username");
        return nombre != null ? nombre : jwt.getSubject();
    }
}
