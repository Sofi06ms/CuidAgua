package com.cuidagua.api.aviso.controller;

import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.entity.TipoAviso;
import com.cuidagua.api.aviso.service.AvisoService;
import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.KeycloakRealmRoleConverter;
import com.cuidagua.api.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Pruebas de la capa web de avisos: seguridad por roles, validaciones y formato de respuesta.
 * No requieren base de datos ni Keycloak.
 */
@WebMvcTest(AvisoController.class)
@Import({SecurityConfig.class, JsonSecurityHandlers.class})
class AvisoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AvisoService avisoService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String AVISO_VALIDO = """
            {
              "titulo": "Corte programado",
              "mensaje": "Se suspenderá el servicio por mantenimiento de la red.",
              "colonia": "Centro",
              "tipo": "CORTE",
              "fechaRestablecimiento": "%s"
            }
            """.formatted(LocalDateTime.now().plusDays(2).withNano(0));

    @Test
    void listarAvisosEsPublico() throws Exception {
        when(avisoService.listar(null)).thenReturn(List.of());

        mockMvc.perform(get("/api/avisos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos").isArray());
    }

    @Test
    void crearAvisoSinTokenDevuelve401() throws Exception {
        mockMvc.perform(postJson(AVISO_VALIDO))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.token").exists());
    }

    @Test
    void crearAvisoComoCiudadanoDevuelve403() throws Exception {
        mockMvc.perform(postJson(AVISO_VALIDO).with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.rol").exists());
    }

    @Test
    void crearAvisoComoAdminDevuelve201() throws Exception {
        AvisoResponse respuesta = new AvisoResponse(1L, "Corte programado", "Mensaje", "Centro",
                TipoAviso.CORTE, null, LocalDateTime.now().plusDays(2), "admin1", LocalDateTime.now());
        when(avisoService.crear(any(), eq("id-admin1"), eq("admin1"))).thenReturn(respuesta);

        mockMvc.perform(postJson(AVISO_VALIDO).with(token("admin1", "ADMIN", "CIUDADANO")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos.id").value(1))
                .andExpect(jsonPath("$.datos.creadoPor").value("admin1"));
    }

    @Test
    void crearAvisoInvalidoDevuelve400ConErroresPorCampo() throws Exception {
        String invalido = """
                {
                  "titulo": "Hoy",
                  "mensaje": "Corto",
                  "colonia": "",
                  "tipo": "CORTE",
                  "fechaRestablecimiento": "2020-01-01T00:00:00"
                }
                """;

        mockMvc.perform(postJson(invalido).with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.titulo").exists())
                .andExpect(jsonPath("$.errores.mensaje").exists())
                .andExpect(jsonPath("$.errores.colonia").exists())
                .andExpect(jsonPath("$.errores.fechaRestablecimiento").exists());
    }

    @Test
    void tipoDeAvisoDesconocidoDevuelve400() throws Exception {
        String invalido = AVISO_VALIDO.replace("\"CORTE\"", "\"INUNDACION\"");

        mockMvc.perform(postJson(invalido).with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.tipo").exists());
    }

    private MockHttpServletRequestBuilder postJson(String cuerpo) {
        return post("/api/avisos").contentType(MediaType.APPLICATION_JSON).content(cuerpo);
    }

    /** Simula un token de Keycloak con los roles en realm_access.roles. */
    private static org.springframework.test.web.servlet.request.RequestPostProcessor token(String usuario, String... roles) {
        return jwt()
                .jwt(j -> j.subject("id-" + usuario)
                        .claim("preferred_username", usuario)
                        .claim("realm_access", Map.of("roles", List.of(roles))))
                .authorities(new KeycloakRealmRoleConverter());
    }
}
