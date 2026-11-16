package com.cuidagua.api.reporte.controller;

import com.cuidagua.api.common.exception.ConflictoException;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.KeycloakRealmRoleConverter;
import com.cuidagua.api.config.SecurityConfig;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.TipoReporte;
import com.cuidagua.api.reporte.service.ReporteService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Pruebas de la capa web de reportes. No requieren base de datos ni Keycloak. */
@WebMvcTest(ReporteController.class)
@Import({SecurityConfig.class, JsonSecurityHandlers.class})
class ReporteControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ReporteService reporteService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String REPORTE_VALIDO = """
            {
              "tipo": "FUGA",
              "descripcion": "Fuga de agua en la banqueta frente al número 25",
              "direccion": "Av. Juárez 25",
              "colonia": "Centro",
              "zona": "Zona Centro",
              "latitud": 19.4326,
              "longitud": -99.1332
            }
            """;

    @Test
    void listarReportesEsPublicoYAplicaTodosLosFiltros() throws Exception {
        ReporteFiltro esperado = new ReporteFiltro(EstadoReporte.PENDIENTE, TipoReporte.FUGA, "Zona Centro", "Centro");
        when(reporteService.listar(esperado)).thenReturn(List.of());

        mockMvc.perform(get("/api/reportes")
                        .param("estado", "PENDIENTE").param("tipo", "FUGA")
                        .param("zona", "Zona Centro").param("colonia", "Centro"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos").isArray());

        verify(reporteService).listar(esperado);
    }

    @Test
    void filtroConEstadoDesconocidoDevuelve400ConValoresPermitidos() throws Exception {
        mockMvc.perform(get("/api/reportes").param("estado", "CERRADO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.estado").value(org.hamcrest.Matchers.containsString("PENDIENTE")));
    }

    @Test
    void crearReporteSinTokenDevuelve401() throws Exception {
        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(REPORTE_VALIDO))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.exito").value(false));
    }

    @Test
    void crearReporteValidoDevuelve201YGuardaUsuarioDelToken() throws Exception {
        when(reporteService.crear(any(), eq("id-ciudadano1"), eq("ciudadano1"))).thenReturn(reporte(EstadoReporte.PENDIENTE));

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(REPORTE_VALIDO)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos.estado").value("PENDIENTE"))
                .andExpect(jsonPath("$.datos.zona").value("Zona Centro"))
                .andExpect(jsonPath("$.datos.usuario").value("ciudadano1"));
    }

    @Test
    void crearReporteInvalidoDevuelve400() throws Exception {
        String invalido = """
                {
                  "descripcion": "Corta",
                  "direccion": "",
                  "colonia": "Centro",
                  "latitud": 120,
                  "longitud": -200
                }
                """;

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(invalido)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.tipo").exists())
                .andExpect(jsonPath("$.errores.descripcion").exists())
                .andExpect(jsonPath("$.errores.direccion").exists())
                .andExpect(jsonPath("$.errores.zona").exists())
                .andExpect(jsonPath("$.errores.latitud").exists())
                .andExpect(jsonPath("$.errores.longitud").exists());
    }

    @Test
    void obtenerReporteInexistenteDevuelve404() throws Exception {
        when(reporteService.obtener(99L)).thenThrow(new RecursoNoEncontradoException("No existe un reporte con id 99"));

        mockMvc.perform(get("/api/reportes/99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.mensaje").value("No existe un reporte con id 99"));
    }

    @Test
    void cambiarEstadoComoCiudadanoDevuelve403() throws Exception {
        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"EN_PROCESO\"}")
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errores.rol").exists());
    }

    @Test
    void cambiarEstadoComoAdminDevuelve200() throws Exception {
        when(reporteService.cambiarEstado(eq(1L), any(), eq("admin1"))).thenReturn(reporte(EstadoReporte.EN_PROCESO));

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"EN_PROCESO\"}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.estado").value("EN_PROCESO"));
    }

    @Test
    void cambiarEstadoNoPermitidoDevuelve409() throws Exception {
        when(reporteService.cambiarEstado(eq(1L), any(), eq("admin1")))
                .thenThrow(new ConflictoException("estado", "El reporte está en estado RESUELTO y ya no puede cambiar"));

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"EN_PROCESO\"}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.estado").exists());
    }

    @Test
    void cambiarEstadoSinEstadoDevuelve400() throws Exception {
        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.estado").exists());
    }

    @Test
    void resumenRequiereRolAdmin() throws Exception {
        mockMvc.perform(get("/api/reportes/resumen")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/reportes/resumen").with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden());
    }

    @Test
    void misReportesRequiereToken() throws Exception {
        mockMvc.perform(get("/api/reportes/mios")).andExpect(status().isUnauthorized());
    }

    private static ReporteResponse reporte(EstadoReporte estado) {
        return new ReporteResponse(1L, TipoReporte.FUGA, "Fuga de agua", "Av. Juárez 25", "Centro", "Zona Centro",
                19.4326, -99.1332, null, estado, "ciudadano1", LocalDateTime.now(), null, null, null);
    }

    private static RequestPostProcessor token(String usuario, String... roles) {
        return jwt()
                .jwt(j -> j.subject("id-" + usuario)
                        .claim("preferred_username", usuario)
                        .claim("realm_access", Map.of("roles", List.of(roles))))
                .authorities(new KeycloakRealmRoleConverter());
    }
}
