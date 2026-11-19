package com.cuidagua.api.reporte.controller;

import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.common.util.JwtUtils;
import com.cuidagua.api.config.OpenApiConfig;
import com.cuidagua.api.reporte.dto.CambioEstadoRequest;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.dto.ResumenReportesResponse;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.TipoReporte;
import com.cuidagua.api.reporte.service.ReporteService;
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
            description = "Cualquier usuario autenticado. El reporte inicia en PENDIENTE y guarda el usuario del token.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PostMapping
    public ResponseEntity<ApiResponse<ReporteResponse>> crear(@Valid @RequestBody ReporteRequest request,
                                                              @AuthenticationPrincipal Jwt jwt) {
        ReporteResponse creado = reporteService.crear(request, jwt.getSubject(), JwtUtils.nombreUsuario(jwt));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Reporte registrado correctamente", creado));
    }

    @Operation(summary = "Consultar reportes",
            description = "Público. Filtros opcionales y combinables. Orden: más recientes primero.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<ReporteResponse>>> listar(
            @Parameter(description = "Estado del reporte") @RequestParam(required = false) EstadoReporte estado,
            @Parameter(description = "Tipo de incidencia") @RequestParam(required = false) TipoReporte tipo,
            @Parameter(description = "Zona (sin distinguir mayúsculas)") @RequestParam(required = false) String zona,
            @Parameter(description = "Colonia (sin distinguir mayúsculas)") @RequestParam(required = false) String colonia) {
        List<ReporteResponse> reportes = reporteService.listar(new ReporteFiltro(estado, tipo, zona, colonia));
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + reportes.size() + " reportes", reportes));
    }

    @Operation(summary = "Mis reportes", description = "Reportes creados por el usuario del token.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/mios")
    public ResponseEntity<ApiResponse<List<ReporteResponse>>> listarMios(@AuthenticationPrincipal Jwt jwt) {
        List<ReporteResponse> reportes = reporteService.listarDeUsuario(jwt.getSubject());
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + reportes.size() + " reportes", reportes));
    }

    @Operation(summary = "Resumen para el panel administrativo",
            description = "Rol ADMIN. Total de reportes y conteo por estado y por tipo (incluye los que valen 0).")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @GetMapping("/resumen")
    public ResponseEntity<ApiResponse<ResumenReportesResponse>> resumen() {
        return ResponseEntity.ok(ApiResponse.ok("Resumen de reportes", reporteService.resumen()));
    }

    @Operation(summary = "Detalle de un reporte", description = "Público. 404 si no existe.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReporteResponse>> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok("Reporte encontrado", reporteService.obtener(id)));
    }

    @Operation(summary = "Cambiar el estado de un reporte",
            description = """
                    Rol ADMIN. Flujo permitido: PENDIENTE → EN_PROCESO | RESUELTO | RECHAZADO; \
                    EN_PROCESO → RESUELTO | RECHAZADO. RESUELTO y RECHAZADO son finales (409). \
                    Al rechazar, el comentario es obligatorio.""")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PatchMapping("/{id}/estado")
    public ResponseEntity<ApiResponse<ReporteResponse>> cambiarEstado(@PathVariable Long id,
                                                                      @Valid @RequestBody CambioEstadoRequest request,
                                                                      @AuthenticationPrincipal Jwt jwt) {
        ReporteResponse actualizado = reporteService.cambiarEstado(id, request, JwtUtils.nombreUsuario(jwt));
        return ResponseEntity.ok(ApiResponse.ok("Estado del reporte actualizado a " + actualizado.estado(), actualizado));
    }
}
