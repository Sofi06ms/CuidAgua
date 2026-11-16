package com.cuidagua.api.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Seguridad de la API: valida tokens JWT de Keycloak y define qué rutas son públicas.
 * Las reglas se evalúan en orden: las rutas específicas van antes que los comodines.
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private static final String ADMIN = "ADMIN";

    private final JsonSecurityHandlers jsonSecurityHandlers;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // API sin sesión ni formularios: CSRF no aplica a peticiones con token Bearer.
                .csrf(csrf -> csrf.disable())
                .cors(cors -> {})
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health/**", "/actuator/info", "/error").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()

                        // Reportes
                        .requestMatchers(HttpMethod.GET, "/api/reportes/resumen").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.GET, "/api/reportes/mios").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/reportes", "/api/reportes/*").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/reportes").authenticated()
                        .requestMatchers(HttpMethod.PATCH, "/api/reportes/*/estado").hasRole(ADMIN)

                        // Avisos: consulta pública, administración solo ADMIN
                        .requestMatchers(HttpMethod.GET, "/api/avisos", "/api/avisos/*").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/avisos").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.PUT, "/api/avisos/*").hasRole(ADMIN)
                        .requestMatchers(HttpMethod.DELETE, "/api/avisos/*").hasRole(ADMIN)

                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                        .authenticationEntryPoint(jsonSecurityHandlers.authenticationEntryPoint())
                        .accessDeniedHandler(jsonSecurityHandlers.accessDeniedHandler()))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(jsonSecurityHandlers.authenticationEntryPoint())
                        .accessDeniedHandler(jsonSecurityHandlers.accessDeniedHandler()));
        return http.build();
    }

    /** Los roles salen de realm_access.roles y el nombre de usuario de preferred_username. */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(new KeycloakRealmRoleConverter());
        converter.setPrincipalClaimName("preferred_username");
        return converter;
    }

    /** CORS abierto para desarrollo (panel web y pruebas desde el navegador). Restringir en producción. */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
