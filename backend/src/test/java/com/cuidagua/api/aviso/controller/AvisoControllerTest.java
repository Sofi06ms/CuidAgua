package com.cuidagua.api.aviso.controller;

import com.cuidagua.api.aviso.dto.AvisoFiltro;
import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.entity.TipoAviso;
import com.cuidagua.api.aviso.service.AvisoService;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.SecurityConfig;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.entity.RolUsuario;
import com.cuidagua.api.zona.dto.ZonaResponse;
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

import static com.cuidagua.api.TokensPrueba.token;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
              "zonaId": 1,
              "tipo": "corte",
              "fechaRestablecimiento": "%s"
            }
            """.formatted(LocalDateTime.now().plusDays(2).withNano(0));

    @Test
    void listarAvisosEsPublico() throws Exception {
        when(avisoService.listar(AvisoFiltro.sinFiltros())).thenReturn(List.of());

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
    void crearAvisoComoCiudadanoOPersonalDevuelve403() throws Exception {
        mockMvc.perform(postJson(AVISO_VALIDO).with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errores.rol").exists());
        mockMvc.perform(postJson(AVISO_VALIDO).with(token("personal1", "PERSONAL")))
                .andExpect(status().isForbidden());
    }

    @Test
    void crearAvisoComoAdminDevuelve201() throws Exception {
        UsuarioToken admin = new UsuarioToken("id-admin1", "Nombre admin1", "admin1@cuidagua.local", true,
                RolUsuario.ADMINISTRADOR);
        AvisoResponse respuesta = new AvisoResponse(1, "Corte programado", "Mensaje", new ZonaResponse(1, "Zona Norte"),
                TipoAviso.CORTE, null, LocalDateTime.now().plusDays(2), true, "Nombre admin1", LocalDateTime.now(), null);
        when(avisoService.crear(any(), eq(admin))).thenReturn(respuesta);

        mockMvc.perform(postJson(AVISO_VALIDO).with(token("admin1", "ADMIN", "CIUDADANO")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos.id").value(1))
                .andExpect(jsonPath("$.datos.tipo").value("corte"))
                .andExpect(jsonPath("$.datos.zona.nombre").value("Zona Norte"))
                .andExpect(jsonPath("$.datos.creadoPor").value("Nombre admin1"));
    }

    @Test
    void crearAvisoInvalidoDevuelve400ConErroresPorCampo() throws Exception {
        String invalido = """
                {
                  "titulo": "Hoy",
                  "mensaje": "Corto",
                  "zonaId": 0,
                  "fechaRestablecimiento": "2020-01-01T00:00:00"
                }
                """;

        mockMvc.perform(postJson(invalido).with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.titulo").exists())
                .andExpect(jsonPath("$.errores.mensaje").exists())
                .andExpect(jsonPath("$.errores.zonaId").exists())
                .andExpect(jsonPath("$.errores.tipo").exists())
                .andExpect(jsonPath("$.errores.fechaRestablecimiento").exists());
    }

    @Test
    void tipoDeAvisoDesconocidoDevuelve400() throws Exception {
        String invalido = AVISO_VALIDO.replace("\"corte\"", "\"inundacion\"");

        mockMvc.perform(postJson(invalido).with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.tipo").value(containsString("corte, restablecimiento")));
    }

    @Test
    void listarAvisosConFiltrosDeZonaTipoYVigencia() throws Exception {
        AvisoFiltro esperado = new AvisoFiltro(1, TipoAviso.BAJA_PRESION, true);
        when(avisoService.listar(esperado)).thenReturn(List.of());

        mockMvc.perform(get("/api/avisos").param("zonaId", "1").param("tipo", "baja_presion").param("vigentes", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true));

        verify(avisoService).listar(esperado);
    }

    @Test
    void obtenerAvisoInexistenteDevuelve404() throws Exception {
        when(avisoService.obtener(5)).thenThrow(new RecursoNoEncontradoException("No existe un aviso con id 5"));

        mockMvc.perform(get("/api/avisos/5"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.exito").value(false));
    }

    @Test
    void editarYEliminarAvisoRequierenRolAdmin() throws Exception {
        mockMvc.perform(put("/api/avisos/1").contentType(MediaType.APPLICATION_JSON).content(AVISO_VALIDO)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/avisos/1").with(token("personal1", "PERSONAL")))
                .andExpect(status().isForbidden());
    }

    @Test
    void eliminarAvisoComoAdminDevuelve200() throws Exception {
        mockMvc.perform(delete("/api/avisos/1").with(token("admin1", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos").doesNotExist());
    }

    private MockHttpServletRequestBuilder postJson(String cuerpo) {
        return post("/api/avisos").contentType(MediaType.APPLICATION_JSON).content(cuerpo);
    }
}
