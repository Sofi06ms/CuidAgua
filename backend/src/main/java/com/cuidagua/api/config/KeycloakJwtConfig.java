package com.cuidagua.api.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Validación de los tokens de Keycloak.
 * <p>
 * Keycloak escribe en el claim {@code iss} la dirección con la que se pidió el token, así que cambia según
 * desde dónde se conecte la app: {@code localhost} (navegador o curl en la PC), {@code 10.0.2.2} (emulador
 * de Android) o la IP de la PC en la red local (celular). Por eso:
 * <ul>
 *   <li>Las llaves públicas (JWKS) se descargan de una dirección fija: {@code KEYCLOAK_JWK_SET_URI}
 *       (dentro de Docker, {@code http://keycloak:8180/...}).</li>
 *   <li>El {@code iss} del token debe ser uno de los de {@code KEYCLOAK_ISSUERS} (separados por comas).</li>
 * </ul>
 * La firma y la expiración se siguen validando siempre.
 */
@Slf4j
@Configuration
public class KeycloakJwtConfig {

    @Bean
    public JwtDecoder jwtDecoder(@Value("${cuidagua.keycloak.jwk-set-uri}") String jwkSetUri,
                                 @Value("${cuidagua.keycloak.issuers}") String issuers) {
        Set<String> permitidos = normalizar(issuers);
        if (permitidos.isEmpty()) {
            throw new IllegalStateException("KEYCLOAK_ISSUERS no puede estar vacío");
        }
        log.info("Tokens aceptados de los issuers {} (llaves en {})", permitidos, jwkSetUri);

        OAuth2TokenValidator<Jwt> issuerPermitido = new JwtClaimValidator<Object>(JwtClaimNames.ISS,
                iss -> iss != null && permitidos.contains(sinDiagonalFinal(iss.toString())));

        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build();
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(JwtValidators.createDefault(), issuerPermitido));
        return decoder;
    }

    static Set<String> normalizar(String issuers) {
        return Arrays.stream(issuers.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(KeycloakJwtConfig::sinDiagonalFinal)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private static String sinDiagonalFinal(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
