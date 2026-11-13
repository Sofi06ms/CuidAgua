package com.cuidagua.api.reporte.controller;

import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.service.ReporteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/reportes")
@RequiredArgsConstructor
public class ReporteController {

    private final ReporteService reporteService;

    /** Registra una incidencia. Requiere token (cualquier usuario autenticado). */
    @PostMapping
    public ResponseEntity<ApiResponse<ReporteResponse>> crear(@Valid @RequestBody ReporteRequest request,
                                                              @AuthenticationPrincipal Jwt jwt) {
        ReporteResponse creado = reporteService.crear(request, jwt.getSubject(), nombreUsuario(jwt));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Reporte registrado correctamente", creado));
    }

    /** Consulta pública de reportes; filtro opcional ?colonia=. */
    @GetMapping
    public ResponseEntity<ApiResponse<List<ReporteResponse>>> listar(
            @RequestParam(required = false) String colonia) {
        List<ReporteResponse> reportes = reporteService.listar(colonia);
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + reportes.size() + " reportes", reportes));
    }

    private String nombreUsuario(Jwt jwt) {
        String nombre = jwt.getClaimAsString("preferred_username");
        return nombre != null ? nombre : jwt.getSubject();
    }
}
