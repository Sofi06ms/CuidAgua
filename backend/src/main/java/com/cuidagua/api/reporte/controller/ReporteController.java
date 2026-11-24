package com.cuidagua.api.reporte.controller;

import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.config.OpenApiConfig;
import com.cuidagua.api.reporte.dto.CambioEstadoRequest;
import com.cuidagua.api.reporte.dto.HistorialEstadoResponse;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.dto.ResumenReportesResponse;
import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.service.ReporteService;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Endpoints de reportes. Las reglas de acceso por rol están en SecurityConfig. */
@Tag(name = "Reportes", description = "Incidencias de agua reportadas por la ciudadanía")
@RestController
@RequestMapping("/api/reportes")
@RequiredArgsConstructor
public class ReporteController {

    private final ReporteService reporteService;

    @Operation(summary = "Registrar un reporte",
            description = """
                    Cualquier usuario autenticado. El reporte inicia en "pendiente", recibe un folio \
                    (ej. CA-2026-000001) y queda ligado al usuario del token. Categorías: fuga, tuberia_danada, \
                    falta_suministro, baja_presion, otro. zonaId sale de GET /api/zonas.""")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PostMapping
    public ResponseEntity<ApiResponse<ReporteResponse>> crear(@Valid @RequestBody ReporteRequest request,
                                                              @AuthenticationPrincipal Jwt jwt) {
        ReporteResponse creado = reporteService.crear(request, UsuarioToken.desde(jwt));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Reporte registrado con folio " + creado.folio(), creado));
    }

    @Operation(summary = "Consultar reportes",
            description = "Público. Filtros opcionales y combinables. Orden: más recientes primero.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<ReporteResponse>>> listar(
            @Parameter(description = "pendiente, en_revision, resuelto o rechazado")
            @RequestParam(required = false) EstadoReporte estado,
            @Parameter(description = "fuga, tuberia_danada, falta_suministro, baja_presion u otro")
            @RequestParam(required = false) CategoriaReporte categoria,
            @Parameter(description = "Id de la zona (GET /api/zonas)")
            @RequestParam(required = false) Integer zonaId) {
        List<ReporteResponse> reportes = reporteService.listar(new ReporteFiltro(estado, categoria, zonaId));
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + reportes.size() + " reportes", reportes));
    }

    @Operation(summary = "Mis reportes", description = "Reportes creados por el usuario del token.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/mios")
    public ResponseEntity<ApiResponse<List<ReporteResponse>>> listarMios(@AuthenticationPrincipal Jwt jwt) {
        List<ReporteResponse> reportes = reporteService.listarDeUsuario(jwt.getSubject());
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + reportes.size() + " reportes", reportes));
    }

    @Operation(summary = "Resumen para el panel",
            description = "Roles ADMIN o PERSONAL. Total de reportes y conteo por estado y por categoría (incluye los que valen 0).")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/resumen")
    public ResponseEntity<ApiResponse<ResumenReportesResponse>> resumen() {
        return ResponseEntity.ok(ApiResponse.ok("Resumen de reportes", reporteService.resumen()));
    }

    @Operation(summary = "Detalle de un reporte", description = "Público. 404 si no existe.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReporteResponse>> obtener(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.ok("Reporte encontrado", reporteService.obtener(id)));
    }

    @Operation(summary = "Historial de estados de un reporte",
            description = "Cualquier usuario autenticado. Del más antiguo al más reciente; el primero es el registro del reporte.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/{id}/historial")
    public ResponseEntity<ApiResponse<List<HistorialEstadoResponse>>> historial(@PathVariable Integer id) {
        List<HistorialEstadoResponse> historial = reporteService.historial(id);
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + historial.size() + " cambios de estado", historial));
    }

    @Operation(summary = "Cambiar el estado de un reporte",
            description = """
                    Roles ADMIN o PERSONAL. Flujo: pendiente → en_revision | resuelto | rechazado; \
                    en_revision → resuelto | rechazado. resuelto y rechazado son finales (409). \
                    Al rechazar, la observación es obligatoria. Cada cambio se guarda en historial_estados.""")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PatchMapping("/{id}/estado")
    public ResponseEntity<ApiResponse<ReporteResponse>> cambiarEstado(@PathVariable Integer id,
                                                                      @Valid @RequestBody CambioEstadoRequest request,
                                                                      @AuthenticationPrincipal Jwt jwt) {
        ReporteResponse actualizado = reporteService.cambiarEstado(id, request, UsuarioToken.desde(jwt));
        return ResponseEntity.ok(ApiResponse.ok("Estado del reporte actualizado a " + actualizado.estado(), actualizado));
    }
}
