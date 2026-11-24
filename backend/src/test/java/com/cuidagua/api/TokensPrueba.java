package com.cuidagua.api;

import com.cuidagua.api.config.KeycloakRealmRoleConverter;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.List;
import java.util.Map;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

/** Tokens de Keycloak simulados para las pruebas. */
public final class TokensPrueba {

    private TokensPrueba() {
    }

    /**
     * Token con sub "id-&lt;usuario&gt;", name "Nombre &lt;usuario&gt;", email "&lt;usuario&gt;@cuidagua.local"
     * (verificado) y los roles indicados en realm_access.roles.
     */
    public static RequestPostProcessor token(String usuario, String... roles) {
        return jwt()
                .jwt(j -> j.subject("id-" + usuario)
                        .claim("preferred_username", usuario)
                        .claim("name", "Nombre " + usuario)
                        .claim("email", usuario + "@cuidagua.local")
                        .claim("email_verified", true)
                        .claim("realm_access", Map.of("roles", List.of(roles))))
                .authorities(new KeycloakRealmRoleConverter());
    }
}
