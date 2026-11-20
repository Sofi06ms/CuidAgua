package com.cuidagua.api.reporte.controller;

import com.cuidagua.api.common.exception.ConflictoException;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.SecurityConfig;
import com.cuidagua.api.reporte.dto.HistorialEstadoResponse;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.service.ReporteService;
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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static com.cuidagua.api.TokensPrueba.token;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
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
              "categoria": "fuga",
              "descripcion": "Fuga de agua en la banqueta frente al número 25",
              "zonaId": 2,
              "latitud": 20.1765,
              "longitud": -98.0535,
              "evidencias": ["https://ejemplo.com/foto1.jpg"]
            }
            """;

    private static final UsuarioToken CIUDADANO1 = new UsuarioToken("id-ciudadano1", "Nombre ciudadano1",
            "ciudadano1@cuidagua.local", true, RolUsuario.CIUDADANO);

    @Test
    void listarReportesEsPublicoYAplicaTodosLosFiltros() throws Exception {
        ReporteFiltro esperado = new ReporteFiltro(EstadoReporte.EN_REVISION, CategoriaReporte.TUBERIA_DANADA, 2);
        when(reporteService.listar(esperado)).thenReturn(List.of());

        mockMvc.perform(get("/api/reportes")
                        .param("estado", "en_revision").param("categoria", "tuberia_danada").param("zonaId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos").isArray());

        verify(reporteService).listar(esperado);
    }

    @Test
    void filtroConEstadoDesconocidoDevuelve400ConValoresPermitidos() throws Exception {
        mockMvc.perform(get("/api/reportes").param("estado", "cerrado"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.estado").value(containsString("pendiente, en_revision, resuelto, rechazado")));
    }

    @Test
    void filtroConZonaNoNumericaDevuelve400() throws Exception {
        mockMvc.perform(get("/api/reportes").param("zonaId", "centro"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.zonaId").exists());
    }

    @Test
    void crearReporteSinTokenDevuelve401() throws Exception {
        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(REPORTE_VALIDO))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.exito").value(false));
    }

    @Test
    void crearReporteValidoDevuelve201ConFolioYUsaElUsuarioDelToken() throws Exception {
        when(reporteService.crear(any(), eq(CIUDADANO1))).thenReturn(reporte(EstadoReporte.PENDIENTE));

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(REPORTE_VALIDO)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.mensaje").value("Reporte registrado con folio CA-2026-000001"))
                .andExpect(jsonPath("$.datos.folio").value("CA-2026-000001"))
                .andExpect(jsonPath("$.datos.categoria").value("fuga"))
                .andExpect(jsonPath("$.datos.estado").value("pendiente"))
                .andExpect(jsonPath("$.datos.zona.nombre").value("Zona Centro"))
                .andExpect(jsonPath("$.datos.usuario").value("Nombre ciudadano1"));

        verify(reporteService).crear(argThat(r -> r.categoria() == CategoriaReporte.FUGA && r.zonaId() == 2
                && r.evidencias().size() == 1), eq(CIUDADANO1));
    }

    @Test
    void crearReporteInvalidoDevuelve400() throws Exception {
        String invalido = """
                {
                  "descripcion": "Corta",
                  "latitud": 120,
                  "longitud": -200,
                  "evidencias": ["no-es-url", "https://a.com/1.jpg", "https://a.com/2.jpg",
                                 "https://a.com/3.jpg", "https://a.com/4.jpg", "https://a.com/5.jpg"]
                }
                """;

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(invalido)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.categoria").exists())
                .andExpect(jsonPath("$.errores.descripcion").exists())
                .andExpect(jsonPath("$.errores.zonaId").exists())
                .andExpect(jsonPath("$.errores.latitud").exists())
                .andExpect(jsonPath("$.errores.longitud").exists())
                .andExpect(jsonPath("$.errores.evidencias").exists())
                .andExpect(jsonPath("$.errores['evidencias[0]']").exists());
    }

    @Test
    void categoriaConNombreAnteriorDevuelve400ConValoresPermitidos() throws Exception {
        String invalido = REPORTE_VALIDO.replace("\"fuga\"", "\"TUBERIA_ROTA\"");

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(invalido)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.categoria").value(containsString("tuberia_danada")));
    }

    @Test
    void obtenerReporteInexistenteDevuelve404() throws Exception {
        when(reporteService.obtener(99)).thenThrow(new RecursoNoEncontradoException("No existe un reporte con id 99"));

        mockMvc.perform(get("/api/reportes/99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.mensaje").value("No existe un reporte con id 99"));
    }

    @Test
    void cambiarEstadoComoCiudadanoDevuelve403() throws Exception {
        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"en_revision\"}")
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errores.rol").exists());
    }

    @Test
    void cambiarEstadoComoAdminDevuelve200() throws Exception {
        UsuarioToken admin = new UsuarioToken("id-admin1", "Nombre admin1", "admin1@cuidagua.local", true,
                RolUsuario.ADMINISTRADOR);
        when(reporteService.cambiarEstado(eq(1), any(), eq(admin))).thenReturn(reporte(EstadoReporte.EN_REVISION));

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"en_revision\",\"observacion\":\"Cuadrilla en camino\"}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mensaje").value("Estado del reporte actualizado a en_revision"))
                .andExpect(jsonPath("$.datos.estado").value("en_revision"));
    }

    @Test
    void cambiarEstadoComoPersonalDevuelve200() throws Exception {
        UsuarioToken personal = new UsuarioToken("id-personal1", "Nombre personal1", "personal1@cuidagua.local", true,
                RolUsuario.PERSONAL);
        when(reporteService.cambiarEstado(eq(1), any(), eq(personal))).thenReturn(reporte(EstadoReporte.RESUELTO));

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"resuelto\"}")
                        .with(token("personal1", "PERSONAL")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.estado").value("resuelto"));
    }

    @Test
    void cambiarEstadoNoPermitidoDevuelve409() throws Exception {
        when(reporteService.cambiarEstado(eq(1), any(), any()))
                .thenThrow(new ConflictoException("estado", "El reporte está en estado resuelto y ya no puede cambiar"));

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"en_revision\"}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.exito").value(false))
                .andExpect(jsonPath("$.errores.estado").exists());
    }

    @Test
    void cambiarEstadoSinEstadoOConValorAnteriorDevuelve400() throws Exception {
        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.estado").exists());

        mockMvc.perform(patch("/api/reportes/1/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"EN_PROCESO\"}")
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.estado").value(containsString("en_revision")));
    }

    @Test
    void historialRequiereTokenYDevuelveLosCambios() throws Exception {
        mockMvc.perform(get("/api/reportes/1/historial")).andExpect(status().isUnauthorized());

        when(reporteService.historial(1)).thenReturn(List.of(
                new HistorialEstadoResponse(1, null, EstadoReporte.PENDIENTE, "Reporte registrado",
                        "Nombre ciudadano1", LocalDateTime.now())));

        mockMvc.perform(get("/api/reportes/1/historial").with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos[0].estadoAnterior").doesNotExist())
                .andExpect(jsonPath("$.datos[0].estadoNuevo").value("pendiente"));
    }

    @Test
    void resumenRequiereRolAdminOPersonal() throws Exception {
        mockMvc.perform(get("/api/reportes/resumen")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/reportes/resumen").with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/reportes/resumen").with(token("personal1", "PERSONAL")))
                .andExpect(status().isOk());
    }

    @Test
    void misReportesRequiereTokenYUsaElSub() throws Exception {
        mockMvc.perform(get("/api/reportes/mios")).andExpect(status().isUnauthorized());

        when(reporteService.listarDeUsuario("id-ciudadano1")).thenReturn(List.of(reporte(EstadoReporte.PENDIENTE)));
        mockMvc.perform(get("/api/reportes/mios").with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos[0].folio").value("CA-2026-000001"));
    }

    private static ReporteResponse reporte(EstadoReporte estado) {
        return new ReporteResponse(1, "CA-2026-000001", CategoriaReporte.FUGA, "Fuga de agua",
                new ZonaResponse(2, "Zona Centro"), new BigDecimal("20.1765"), new BigDecimal("-98.0535"),
                estado, "Nombre ciudadano1", List.of(), LocalDateTime.now(), LocalDateTime.now());
    }
}
