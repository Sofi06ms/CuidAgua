package com.cuidagua.api.integracion;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.time.LocalDateTime;
import java.time.Year;
import java.util.List;
import java.util.Map;

import static com.cuidagua.api.TokensPrueba.token;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Pruebas de integración API + PostgreSQL: recorren controlador, servicio, repositorio y base de datos reales
 * con las migraciones V1 (esquema oficial) y V2 (ajustes). Solo se simula el token de Keycloak.
 * <p>
 * Requieren PostgreSQL en marcha. Se ejecutan con {@code mvn verify} y usan el esquema "pruebas",
 * que se vacía y se vuelve a migrar al arrancar.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("it")
class ApiPostgresIT {

    /** Zonas del catálogo cargado en V1. */
    private static final int ZONA_NORTE = 1;
    private static final int ZONA_CENTRO = 2;
    private static final int ZONA_SUR = 3;

    private static final RequestPostProcessor CIUDADANO1 = token("ciudadano1", "CIUDADANO");
    private static final RequestPostProcessor PERSONAL1 = token("personal1", "PERSONAL");
    private static final RequestPostProcessor ADMIN1 = token("admin1", "ADMIN");

    @TestConfiguration
    static class EsquemaLimpio {
        /** Vacía el esquema "pruebas" y aplica las migraciones actuales. */
        @Bean
        FlywayMigrationStrategy limpiarYMigrar() {
            return flyway -> {
                flyway.clean();
                flyway.migrate();
            };
        }
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @BeforeEach
    void limpiarTablas() {
        // Las zonas son catálogo de V1 y se conservan.
        jdbc.execute("TRUNCATE historial_estados, asignaciones, evidencias, reportes, avisos, usuarios "
                + "RESTART IDENTITY CASCADE");
    }

    // ---------------------------------------------------------------- Zonas

    @Test
    void zonasDelCatalogoDeV1() throws Exception {
        mockMvc.perform(get("/api/zonas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos[*].nombre", contains("Zona Norte", "Zona Centro", "Zona Sur")));
    }

    // ---------------------------------------------------------------- Usuarios

    @Test
    void elUsuarioDelTokenSeCreaUnaSolaVezSinContrasena() throws Exception {
        crearReporte("fuga", ZONA_CENTRO);
        crearReporte("fuga", ZONA_NORTE);

        List<Map<String, Object>> usuarios = jdbc.queryForList("SELECT * FROM usuarios");
        assertThat(usuarios).hasSize(1);
        Map<String, Object> usuario = usuarios.get(0);
        assertThat(usuario.get("keycloak_id")).isEqualTo("id-ciudadano1");
        assertThat(usuario.get("nombre")).isEqualTo("Nombre ciudadano1");
        assertThat(usuario.get("correo")).isEqualTo("ciudadano1@cuidagua.local");
        assertThat(usuario.get("credencial_hash")).isEqualTo("KEYCLOAK");
        assertThat(usuario.get("rol")).isEqualTo("ciudadano");
        assertThat(usuario.get("fecha_registro")).isNotNull();
    }

    @Test
    void usuarioExistenteSinKeycloakIdSeVinculaPorCorreoVerificado() throws Exception {
        jdbc.update("INSERT INTO usuarios (nombre, correo, credencial_hash, rol) VALUES (?, ?, ?, ?)",
                "Alta previa", "ciudadano1@cuidagua.local", "KEYCLOAK", "ciudadano");

        crearReporte("fuga", ZONA_CENTRO);

        assertThat(jdbc.queryForObject("SELECT count(*) FROM usuarios", Long.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT keycloak_id FROM usuarios", String.class)).isEqualTo("id-ciudadano1");
    }

    @Test
    void correoDeOtraCuentaDevuelve409() throws Exception {
        jdbc.update("INSERT INTO usuarios (nombre, correo, credencial_hash, rol, keycloak_id) VALUES (?, ?, ?, ?, ?)",
                "Otra cuenta", "ciudadano1@cuidagua.local", "KEYCLOAK", "ciudadano", "otro-sub");

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte("fuga", ZONA_CENTRO)).with(CIUDADANO1))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errores.correo").exists());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM reportes", Long.class)).isZero();
    }

    // ---------------------------------------------------------------- Reportes

    @Test
    void registrarReporteGuardaFolioEvidenciasEHistorialInicial() throws Exception {
        MvcResult resultado = mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "categoria": "tuberia_danada",
                                  "descripcion": "  Tubería rota frente a la escuela  ",
                                  "zonaId": %d,
                                  "latitud": 20.17654321,
                                  "longitud": -98.05351234,
                                  "evidencias": ["https://ejemplo.com/foto1.jpg", "https://ejemplo.com/foto2.jpg"]
                                }
                                """.formatted(ZONA_SUR))
                        .with(CIUDADANO1))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.datos.folio").value(matchesPattern("CA-" + Year.now() + "-\\d{6}")))
                .andExpect(jsonPath("$.datos.estado").value("pendiente"))
                .andExpect(jsonPath("$.datos.categoria").value("tuberia_danada"))
                .andExpect(jsonPath("$.datos.descripcion").value("Tubería rota frente a la escuela"))
                .andExpect(jsonPath("$.datos.zona.nombre").value("Zona Sur"))
                .andExpect(jsonPath("$.datos.latitud").value(20.17654321))
                .andExpect(jsonPath("$.datos.evidencias", hasSize(2)))
                .andExpect(jsonPath("$.datos.evidencias[0].url").value("https://ejemplo.com/foto1.jpg"))
                .andReturn();
        int id = idDe(resultado);

        Map<String, Object> fila = jdbc.queryForMap("SELECT * FROM reportes WHERE id = ?", id);
        assertThat(fila.get("estado")).isEqualTo("pendiente");
        assertThat(fila.get("categoria")).isEqualTo("tuberia_danada");
        assertThat(fila.get("zona_id")).isEqualTo(ZONA_SUR);
        assertThat(fila.get("fecha_creacion")).isNotNull();
        assertThat(fila.get("fecha_actualizacion")).isNotNull();

        assertThat(jdbc.queryForObject("SELECT count(*) FROM evidencias WHERE reporte_id = ?", Long.class, id))
                .isEqualTo(2);

        Map<String, Object> historial = jdbc.queryForMap("SELECT * FROM historial_estados WHERE reporte_id = ?", id);
        assertThat(historial.get("estado_anterior")).isNull();
        assertThat(historial.get("estado_nuevo")).isEqualTo("pendiente");
    }

    @Test
    void losFoliosSonUnicosYConsecutivos() throws Exception {
        String folio1 = folioDe(crearReporte("fuga", ZONA_CENTRO));
        String folio2 = folioDe(crearReporte("fuga", ZONA_CENTRO));

        long n1 = Long.parseLong(folio1.substring(folio1.lastIndexOf('-') + 1));
        long n2 = Long.parseLong(folio2.substring(folio2.lastIndexOf('-') + 1));
        assertThat(n2).isEqualTo(n1 + 1);
    }

    @Test
    void consultarReportesFiltraPorEstadoCategoriaYZona() throws Exception {
        int fugaCentro = crearReporte("fuga", ZONA_CENTRO);
        int sinAguaCentro = crearReporte("falta_suministro", ZONA_CENTRO);
        int fugaNorte = crearReporte("fuga", ZONA_NORTE);
        cambiarEstado(fugaNorte, "en_revision", null, PERSONAL1).andExpect(status().isOk());

        // Sin filtros: todos, más recientes primero
        mockMvc.perform(get("/api/reportes"))
                .andExpect(jsonPath("$.datos[*].id", contains(fugaNorte, sinAguaCentro, fugaCentro)));

        mockMvc.perform(get("/api/reportes").param("zonaId", String.valueOf(ZONA_CENTRO)))
                .andExpect(jsonPath("$.datos[*].id", contains(sinAguaCentro, fugaCentro)));

        mockMvc.perform(get("/api/reportes").param("categoria", "fuga"))
                .andExpect(jsonPath("$.datos[*].id", contains(fugaNorte, fugaCentro)));

        mockMvc.perform(get("/api/reportes").param("estado", "en_revision"))
                .andExpect(jsonPath("$.datos[*].id", contains(fugaNorte)));

        mockMvc.perform(get("/api/reportes").param("categoria", "fuga")
                        .param("zonaId", String.valueOf(ZONA_CENTRO)).param("estado", "pendiente"))
                .andExpect(jsonPath("$.datos[*].id", contains(fugaCentro)));
    }

    @Test
    void obtenerReportePorIdYReporteInexistente() throws Exception {
        int id = crearReporte("fuga", ZONA_CENTRO);

        mockMvc.perform(get("/api/reportes/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.id").value(id))
                .andExpect(jsonPath("$.datos.usuario").value("Nombre ciudadano1"));

        mockMvc.perform(get("/api/reportes/{id}", id + 1000))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.exito").value(false));
    }

    @Test
    void cambiosDeEstadoSeGuardanEnElHistorial() throws Exception {
        int id = crearReporte("tuberia_danada", ZONA_SUR);

        cambiarEstado(id, "en_revision", "Cuadrilla asignada", PERSONAL1)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.estado").value("en_revision"));

        // No se puede regresar a pendiente
        cambiarEstado(id, "pendiente", null, ADMIN1).andExpect(status().isConflict());

        cambiarEstado(id, "resuelto", "Tubería reparada", ADMIN1).andExpect(status().isOk());

        // resuelto es final
        cambiarEstado(id, "rechazado", "Duplicado", ADMIN1)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errores.estado").exists());

        assertThat(jdbc.queryForObject("SELECT estado FROM reportes WHERE id = ?", String.class, id))
                .isEqualTo("resuelto");

        mockMvc.perform(get("/api/reportes/{id}/historial", id).with(CIUDADANO1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos", hasSize(3)))
                .andExpect(jsonPath("$.datos[*].estadoNuevo", contains("pendiente", "en_revision", "resuelto")))
                .andExpect(jsonPath("$.datos[1].estadoAnterior").value("pendiente"))
                .andExpect(jsonPath("$.datos[1].observacion").value("Cuadrilla asignada"))
                .andExpect(jsonPath("$.datos[1].responsable").value("Nombre personal1"))
                .andExpect(jsonPath("$.datos[2].responsable").value("Nombre admin1"));

        // Los responsables quedaron registrados con su rol
        assertThat(jdbc.queryForList("SELECT rol FROM usuarios ORDER BY id", String.class))
                .containsExactly("ciudadano", "personal", "administrador");
    }

    @Test
    void historialDeReporteInexistenteDevuelve404() throws Exception {
        mockMvc.perform(get("/api/reportes/{id}/historial", 999).with(CIUDADANO1))
                .andExpect(status().isNotFound());
    }

    @Test
    void rechazarSinObservacionDevuelve400YNoCambiaElEstado() throws Exception {
        int id = crearReporte("otro", ZONA_CENTRO);

        cambiarEstado(id, "rechazado", "   ", ADMIN1)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.observacion").exists());

        assertThat(jdbc.queryForObject("SELECT estado FROM reportes WHERE id = ?", String.class, id))
                .isEqualTo("pendiente");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM historial_estados WHERE reporte_id = ?", Long.class, id))
                .isEqualTo(1);
    }

    @Test
    void zonaInexistenteDevuelve400() throws Exception {
        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte("fuga", 999)).with(CIUDADANO1))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.zonaId").value("No existe una zona con id 999"));

        assertThat(jdbc.queryForObject("SELECT count(*) FROM reportes", Long.class)).isZero();
    }

    @Test
    void latitudSinLongitudDevuelve400() throws Exception {
        String cuerpo = cuerpoReporte("fuga", ZONA_CENTRO).replace("\"longitud\": -98.0535", "\"longitud\": null");

        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON).content(cuerpo).with(CIUDADANO1))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.longitud").exists());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM reportes", Long.class)).isZero();
    }

    @Test
    void misReportesSoloDevuelveLosDelUsuario() throws Exception {
        crearReporte("fuga", ZONA_CENTRO);
        mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte("falta_suministro", ZONA_NORTE))
                        .with(token("ciudadano2", "CIUDADANO")))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/reportes/mios").with(token("ciudadano2", "CIUDADANO")))
                .andExpect(jsonPath("$.datos", hasSize(1)))
                .andExpect(jsonPath("$.datos[0].usuario").value("Nombre ciudadano2"));
    }

    @Test
    void resumenCuentaPorEstadoYCategoria() throws Exception {
        crearReporte("fuga", ZONA_CENTRO);
        crearReporte("fuga", ZONA_CENTRO);
        int otro = crearReporte("falta_suministro", ZONA_NORTE);
        cambiarEstado(otro, "en_revision", null, ADMIN1).andExpect(status().isOk());

        mockMvc.perform(get("/api/reportes/resumen").with(PERSONAL1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.total").value(3))
                .andExpect(jsonPath("$.datos.porEstado.pendiente").value(2))
                .andExpect(jsonPath("$.datos.porEstado.en_revision").value(1))
                .andExpect(jsonPath("$.datos.porEstado.resuelto").value(0))
                .andExpect(jsonPath("$.datos.porCategoria.fuga").value(2))
                .andExpect(jsonPath("$.datos.porCategoria.falta_suministro").value(1))
                .andExpect(jsonPath("$.datos.porCategoria.otro").value(0));
    }

    @Test
    void laBaseDeDatosRechazaEstadosYCategoriasFueraDelCatalogo() throws Exception {
        int id = crearReporte("fuga", ZONA_CENTRO);

        assertThatThrownBy(() -> jdbc.update("UPDATE reportes SET estado = 'EN_PROCESO' WHERE id = ?", id))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("UPDATE reportes SET categoria = 'inundacion' WHERE id = ?", id))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    // ---------------------------------------------------------------- Avisos

    @Test
    void registrarConsultarEditarYEliminarAviso() throws Exception {
        LocalDateTime restablecimiento = LocalDateTime.now().plusDays(1).withNano(0);
        MvcResult creado = mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso("corte", ZONA_CENTRO, restablecimiento))
                        .with(ADMIN1))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.datos.vigente").value(true))
                .andExpect(jsonPath("$.datos.creadoPor").value("Nombre admin1"))
                .andExpect(jsonPath("$.datos.fechaPublicacion").isNotEmpty())
                .andReturn();
        int id = idDe(creado);

        Map<String, Object> fila = jdbc.queryForMap(
                "SELECT a.tipo, a.zona_id, u.keycloak_id FROM avisos a JOIN usuarios u ON u.id = a.creado_por_id "
                        + "WHERE a.id = ?", id);
        assertThat(fila).containsEntry("tipo", "corte").containsEntry("zona_id", ZONA_CENTRO)
                .containsEntry("keycloak_id", "id-admin1");

        mockMvc.perform(get("/api/avisos/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.zona.nombre").value("Zona Centro"));

        mockMvc.perform(put("/api/avisos/{id}", id).contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso("mantenimiento", ZONA_NORTE, restablecimiento.plusDays(1)))
                        .with(ADMIN1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos.tipo").value("mantenimiento"))
                .andExpect(jsonPath("$.datos.zona.nombre").value("Zona Norte"))
                .andExpect(jsonPath("$.datos.fechaActualizacion").isNotEmpty());

        mockMvc.perform(delete("/api/avisos/{id}", id).with(ADMIN1))
                .andExpect(status().isOk());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM avisos", Long.class)).isZero();

        mockMvc.perform(get("/api/avisos/{id}", id)).andExpect(status().isNotFound());
    }

    @Test
    void avisoSinZonaEsGeneral() throws Exception {
        String cuerpo = cuerpoAviso("corte", ZONA_CENTRO, LocalDateTime.now().plusDays(1).withNano(0))
                .replace("\"zonaId\": " + ZONA_CENTRO + ",", "");

        mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON).content(cuerpo).with(ADMIN1))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.datos.zona").doesNotExist());
    }

    @Test
    void consultarAvisosFiltraPorZonaTipoYVigencia() throws Exception {
        int vigenteCentro = crearAviso("corte", ZONA_CENTRO, LocalDateTime.now().plusDays(1));
        int vigenteNorte = crearAviso("baja_presion", ZONA_NORTE, LocalDateTime.now().plusDays(2));
        // Aviso vencido: se ajusta directo en la BD porque la API exige fechas futuras.
        int vencido = crearAviso("corte", ZONA_CENTRO, LocalDateTime.now().plusDays(1));
        jdbc.update("UPDATE avisos SET fecha_restablecimiento = ? WHERE id = ?",
                LocalDateTime.now().minusHours(1), vencido);

        mockMvc.perform(get("/api/avisos").param("vigentes", "true"))
                .andExpect(jsonPath("$.datos[*].id", contains(vigenteNorte, vigenteCentro)));

        mockMvc.perform(get("/api/avisos").param("vigentes", "false"))
                .andExpect(jsonPath("$.datos[*].id", contains(vencido)))
                .andExpect(jsonPath("$.datos[0].vigente").value(false));

        mockMvc.perform(get("/api/avisos").param("zonaId", String.valueOf(ZONA_CENTRO)).param("tipo", "corte"))
                .andExpect(jsonPath("$.datos", hasSize(2)));
    }

    @Test
    void avisoConFechaInicioPosteriorAlRestablecimientoDevuelve400() throws Exception {
        LocalDateTime restablecimiento = LocalDateTime.now().plusDays(1).withNano(0);
        String cuerpo = cuerpoAviso("corte", ZONA_CENTRO, restablecimiento)
                .replace("\"tipo\"", "\"fechaInicio\": \"" + restablecimiento.plusHours(2) + "\",\n  \"tipo\"");

        mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON).content(cuerpo).with(ADMIN1))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.fechaInicio").exists());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM avisos", Long.class)).isZero();
    }

    // ---------------------------------------------------------------- Utilidades

    private int crearReporte(String categoria, int zonaId) throws Exception {
        MvcResult resultado = mockMvc.perform(post("/api/reportes").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoReporte(categoria, zonaId))
                        .with(CIUDADANO1))
                .andExpect(status().isCreated())
                .andReturn();
        return idDe(resultado);
    }

    private int crearAviso(String tipo, int zonaId, LocalDateTime restablecimiento) throws Exception {
        MvcResult resultado = mockMvc.perform(post("/api/avisos").contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpoAviso(tipo, zonaId, restablecimiento.withNano(0)))
                        .with(ADMIN1))
                .andExpect(status().isCreated())
                .andReturn();
        return idDe(resultado);
    }

    private ResultActions cambiarEstado(int id, String estado, String observacion, RequestPostProcessor quien)
            throws Exception {
        String cuerpo = objectMapper.writeValueAsString(
                observacion == null ? Map.of("estado", estado) : Map.of("estado", estado, "observacion", observacion));
        return mockMvc.perform(patch("/api/reportes/{id}/estado", id).contentType(MediaType.APPLICATION_JSON)
                .content(cuerpo)
                .with(quien));
    }

    private String folioDe(int id) {
        return jdbc.queryForObject("SELECT folio FROM reportes WHERE id = ?", String.class, id);
    }

    private static String cuerpoReporte(String categoria, int zonaId) {
        return """
                {
                  "categoria": "%s",
                  "descripcion": "Incidencia de prueba con descripción suficiente",
                  "zonaId": %d,
                  "latitud": 20.1765,
                  "longitud": -98.0535
                }
                """.formatted(categoria, zonaId);
    }

    private static String cuerpoAviso(String tipo, int zonaId, LocalDateTime restablecimiento) {
        return """
                {
                  "titulo": "Aviso de prueba",
                  "mensaje": "Mensaje de prueba para la ciudadanía.",
                  "zonaId": %d,
                  "tipo": "%s",
                  "fechaRestablecimiento": "%s"
                }
                """.formatted(zonaId, tipo, restablecimiento);
    }

    private int idDe(MvcResult resultado) throws Exception {
        JsonNode json = objectMapper.readTree(resultado.getResponse().getContentAsString());
        return json.path("datos").path("id").asInt();
    }
}
