package com.cuidagua.api.integracion;

import com.cuidagua.api.aviso.repository.AvisoRepository;
import com.cuidagua.api.config.KeycloakRealmRoleConverter;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.reporte.repository.ReporteRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Pruebas de integración API + PostgreSQL: recorren controlador, servicio, repositorio y base de datos reales
 * (con migraciones de Flyway). Solo se simula el token de Keycloak.
 * <p>
 * Requieren PostgreSQL en marcha. Se ejecutan con {@code mvn verify}.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("it")
class ApiPostgresIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ReporteRepository reporteRepository;

    @Autowired
    private AvisoRepository avisoRepository;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @BeforeEach
    void limpiarTablas() {
        reporteRepository.deleteAll();
        avisoRepository.deleteAll();
    }

    // ---------------------------------------------------------------- Reportes

    @Test
    void registrarReporteLoGuardaEnPostgresConDatosDelToken() throws Exception {
        long id = crearReporte("FUGA", "Zona Centro", "Centro");

        Reporte guardado = reporteRepository.findById(id).orElseThrow();
        assertThat(guardado.getEstado()).isEqualTo(EstadoReporte.PENDIENTE);
        assertThat(guardado.getZona()).isEqualTo("Zona Centro");
        assertThat(guardado.getUsuarioId()).isEqualTo("id-ciudadano1");
        assertThat(guardado.getUsuarioNombre()).isEqualTo("ciudadano1");
        assertThat(guardado.getFechaCreacion()).isNotNull();
    }

    @Test
    void textosSeGuardanSinEspaciosSobrantes() throws Exception {
        long id = crearReporte("FUGA", "  Zona Norte  ", "  Lomas ");

        Reporte guardado = reporteRepository.findById(id).orElseThrow();
        assertThat(guardado.getZona()).isEqualTo("Zona Norte");
        assertThat(guardado.getColonia()).isEqualTo("Lomas");
    }

    @Test
    void consultarReportesFiltraPorEstadoTipoYZona() throws Exception {
        long fugaCentro = crearReporte("FUGA", "Zona Centro", "Centro");
        long sinAguaCentro = crearReporte("SIN_AGUA", "Zona Centro", "Centro");
        long fugaNorte = crearReporte("FUGA", "Zona Norte", "Lomas");
        cambiarEstado(fugaNorte, "EN_PROCESO", null).andExpect(status().isOk());

        // Sin filtros: todos, más recientes primero
        mockMvc.perform(get("/api/reportes"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) fugaNorte, (int) sinAguaCentro, (int) fugaCentro)));

        // Zona sin distinguir mayúsculas
        mockMvc.perform(get("/api/reportes").param("zona", "zona centro"))
                .andExpect(jsonPath("$.datos", hasSize(2)));

        // Tipo
        mockMvc.perform(get("/api/reportes").param("tipo", "FUGA"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) fugaNorte, (int) fugaCentro)));

        // Estado
        mockMvc.perform(get("/api/reportes").param("estado", "EN_PROCESO"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) fugaNorte)));

        // Combinados
        mockMvc.perform(get("/api/reportes").param("tipo", "FUGA").param("zona", "Zona Centro").param("estado", "PENDIENTE"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) fugaCentro)));

        // Colonia
        mockMvc.perform(get("/api/reportes").param("colonia", "LOMAS"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) fugaNorte)));
    }

    @Test
    void obtenerReportePorIdYReporteInexistente() throws Exception {
        long id = crearReporte("FUGA", "Zona Centro", "Centro");

        mockMvc.perform(get("/api/reportes/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.id").value(id));

        mockMvc.perform(get("/api/reportes/{id}", id + 1000))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.exito").value(false));
    }

    @Test
    void flujoDeEstadosSeRespetaYQuedaRegistrado() throws Exception {
        long id = crearReporte("TUBERIA_ROTA", "Zona Sur", "Jardines");

        cambiarEstado(id, "EN_PROCESO", "Cuadrilla asignada")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.estado").value("EN_PROCESO"))
                .andExpect(jsonPath("$.datos.actualizadoPor").value("admin1"))
                .andExpect(jsonPath("$.datos.comentarioEstado").value("Cuadrilla asignada"));

        // No se puede regresar a PENDIENTE
        cambiarEstado(id, "PENDIENTE", null).andExpect(status().isConflict());

        cambiarEstado(id, "RESUELTO", "Tubería reparada").andExpect(status().isOk());

        // RESUELTO es final
        cambiarEstado(id, "RECHAZADO", "Duplicado")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errores.estado").exists());

        Reporte guardado = reporteRepository.findById(id).orElseThrow();
        assertThat(guardado.getEstado()).isEqualTo(EstadoReporte.RESUELTO);
        assertThat(guardado.getFechaActualizacion()).isNotNull();
    }

    @Test
    void rechazarSinComentarioDevuelve400YNoCambiaElEstado() throws Exception {
        long id = crearReporte("OTRO", "Zona Centro", "Centro");

        cambiarEstado(id, "RECHAZADO", "   ")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.comentario").exists());

        assertThat(reporteRepository.findById(id).orElseThrow().getEstado()).isEqualTo(EstadoReporte.PENDIENTE);
    }

    @Test
    void latitudSinLongitudDevuelve400() throws Exception {
        String cuerpo = cuerpoReporte("FUGA", "Zona Centro", "Centro").replace("\"longitud\": -99.1332", "\"longitud\": null");

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(cuerpo)
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.longitud").exists());

        assertThat(reporteRepository.count()).isZero();
    }

    @Test
    void misReportesSoloDevuelveLosDelUsuario() throws Exception {
        crearReporte("FUGA", "Zona Centro", "Centro");
        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte("SIN_AGUA", "Zona Norte", "Lomas"))
                        .with(token("ciudadano2", "CIUDADANO")))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/reportes/mios").with(token("ciudadano2", "CIUDADANO")))
                .andExpect(jsonPath("$.datos", hasSize(1)))
                .andExpect(jsonPath("$.datos[0].usuario").value("ciudadano2"));
    }

    @Test
    void resumenCuentaPorEstadoYTipo() throws Exception {
        crearReporte("FUGA", "Zona Centro", "Centro");
        crearReporte("FUGA", "Zona Centro", "Centro");
        long otro = crearReporte("SIN_AGUA", "Zona Norte", "Lomas");
        cambiarEstado(otro, "EN_PROCESO", null).andExpect(status().isOk());

        mockMvc.perform(get("/api/reportes/resumen").with(token("admin1", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.total").value(3))
                .andExpect(jsonPath("$.datos.porEstado.PENDIENTE").value(2))
                .andExpect(jsonPath("$.datos.porEstado.EN_PROCESO").value(1))
                .andExpect(jsonPath("$.datos.porEstado.RESUELTO").value(0))
                .andExpect(jsonPath("$.datos.porTipo.FUGA").value(2))
                .andExpect(jsonPath("$.datos.porTipo.SIN_AGUA").value(1));
    }

    // ---------------------------------------------------------------- Avisos

    @Test
    void registrarConsultarEditarYEliminarAviso() throws Exception {
        LocalDateTime restablecimiento = LocalDateTime.now().plusDays(1).withNano(0);
        MvcResult creado = mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso("CORTE", "Zona Centro", restablecimiento))
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.datos.vigente").value(true))
                .andExpect(jsonPath("$.datos.creadoPor").value("admin1"))
                .andReturn();
        long id = idDe(creado);
        assertThat(avisoRepository.findById(id)).isPresent();

        mockMvc.perform(get("/api/avisos/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.zona").value("Zona Centro"));

        mockMvc.perform(put("/api/avisos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso("MANTENIMIENTO", "Zona Norte", restablecimiento.plusDays(1)))
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.tipo").value("MANTENIMIENTO"))
                .andExpect(jsonPath("$.datos.zona").value("Zona Norte"))
                .andExpect(jsonPath("$.datos.fechaActualizacion").isNotEmpty());

        mockMvc.perform(delete("/api/avisos/{id}", id).with(token("admin1", "ADMIN")))
                .andExpect(status().isOk());
        assertThat(avisoRepository.findById(id)).isEmpty();

        mockMvc.perform(get("/api/avisos/{id}", id)).andExpect(status().isNotFound());
    }

    @Test
    void consultarAvisosFiltraPorZonaTipoYVigencia() throws Exception {
        long vigenteCentro = crearAviso("CORTE", "Zona Centro", LocalDateTime.now().plusDays(1));
        long vigenteNorte = crearAviso("BAJA_PRESION", "Zona Norte", LocalDateTime.now().plusDays(2));
        // Aviso vencido: se inserta directo porque la API exige fechas futuras.
        var vencido = avisoRepository.findById(crearAviso("CORTE", "Zona Centro", LocalDateTime.now().plusDays(1)))
                .orElseThrow();
        vencido.setFechaRestablecimiento(LocalDateTime.now().minusHours(1));
        avisoRepository.save(vencido);

        mockMvc.perform(get("/api/avisos").param("vigentes", "true"))
                .andExpect(jsonPath("$.datos[*].id", contains((int) vigenteNorte, (int) vigenteCentro)));

        mockMvc.perform(get("/api/avisos").param("vigentes", "false"))
                .andExpect(jsonPath("$.datos[*].id", contains(vencido.getId().intValue())))
                .andExpect(jsonPath("$.datos[0].vigente").value(false));

        mockMvc.perform(get("/api/avisos").param("zona", "ZONA CENTRO").param("tipo", "CORTE"))
                .andExpect(jsonPath("$.datos", hasSize(2)));
    }

    @Test
    void avisoConFechaInicioPosteriorAlRestablecimientoDevuelve400() throws Exception {
        LocalDateTime restablecimiento = LocalDateTime.now().plusDays(1).withNano(0);
        String cuerpo = cuerpoAviso("CORTE", "Zona Centro", restablecimiento)
                .replace("\"tipo\"", "\"fechaInicio\": \"" + restablecimiento.plusHours(2) + "\",\n  \"tipo\"");

        mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON).content(cuerpo)
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.fechaInicio").exists());

        assertThat(avisoRepository.count()).isZero();
    }

    // ---------------------------------------------------------------- Utilidades

    private long crearReporte(String tipo, String zona, String colonia) throws Exception {
        MvcResult resultado = mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte(tipo, zona, colonia))
                        .with(token("ciudadano1", "CIUDADANO")))
                .andExpect(status().isCreated())
                .andReturn();
        return idDe(resultado);
    }

    private long crearAviso(String tipo, String zona, LocalDateTime restablecimiento) throws Exception {
        MvcResult resultado = mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso(tipo, zona, restablecimiento.withNano(0)))
                        .with(token("admin1", "ADMIN")))
                .andExpect(status().isCreated())
                .andReturn();
        return idDe(resultado);
    }

    private org.springframework.test.web.servlet.ResultActions cambiarEstado(long id, String estado, String comentario)
            throws Exception {
        String cuerpo = objectMapper.writeValueAsString(
                comentario == null ? Map.of("estado", estado) : Map.of("estado", estado, "comentario", comentario));
        return mockMvc.perform(patch("/api/reportes/{id}/estado", id).contentType(MediaType.APPLICATION_JSON)
                .content(cuerpo)
                .with(token("admin1", "ADMIN")));
    }

    private static String cuerpoReporte(String tipo, String zona, String colonia) {
        return """
                {
                  "tipo": "%s",
                  "descripcion": "Incidencia de prueba con descripción suficiente",
                  "direccion": "Calle Falsa 123",
                  "colonia": "%s",
                  "zona": "%s",
                  "latitud": 19.4326,
                  "longitud": -99.1332
                }
                """.formatted(tipo, colonia, zona);
    }

    private static String cuerpoAviso(String tipo, String zona, LocalDateTime restablecimiento) {
        return """
                {
                  "titulo": "Aviso de prueba",
                  "mensaje": "Mensaje de prueba para la ciudadanía.",
                  "colonia": "Centro",
                  "zona": "%s",
                  "tipo": "%s",
                  "fechaRestablecimiento": "%s"
                }
                """.formatted(zona, tipo, restablecimiento);
    }

    private long idDe(MvcResult resultado) throws Exception {
        JsonNode json = objectMapper.readTree(resultado.getResponse().getContentAsString());
        return json.path("datos").path("id").asLong();
    }

    private static RequestPostProcessor token(String usuario, String... roles) {
        return jwt()
                .jwt(j -> j.subject("id-" + usuario)
                        .claim("preferred_username", usuario)
                        .claim("realm_access", Map.of("roles", List.of(roles))))
                .authorities(new KeycloakRealmRoleConverter());
    }
}
