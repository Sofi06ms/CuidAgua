package com.cuidagua.api.aviso.controller;

import com.cuidagua.api.aviso.dto.AvisoFiltro;
import com.cuidagua.api.aviso.dto.AvisoRequest;
import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.entity.TipoAviso;
import com.cuidagua.api.aviso.service.AvisoService;
import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.common.util.JwtUtils;
import com.cuidagua.api.config.OpenApiConfig;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Endpoints de avisos de suministro. Crear, editar y eliminar requieren rol ADMIN (SecurityConfig). */
@Tag(name = "Avisos", description = "Avisos de suministro de agua publicados por administradores")
@RestController
@RequestMapping("/api/avisos")
@RequiredArgsConstructor
public class AvisoController {

    private final AvisoService avisoService;

    @Operation(summary = "Publicar un aviso", description = "Rol ADMIN.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PostMapping
    public ResponseEntity<ApiResponse<AvisoResponse>> crear(@Valid @RequestBody AvisoRequest request,
                                                            @AuthenticationPrincipal Jwt jwt) {
        AvisoResponse creado = avisoService.crear(request, jwt.getSubject(), JwtUtils.nombreUsuario(jwt));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Aviso publicado correctamente", creado));
    }

    @Operation(summary = "Consultar avisos",
            description = "Público. Filtros opcionales y combinables. Orden: más recientes primero.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<AvisoResponse>>> listar(
            @Parameter(description = "Zona (sin distinguir mayúsculas)") @RequestParam(required = false) String zona,
            @Parameter(description = "Colonia (sin distinguir mayúsculas)") @RequestParam(required = false) String colonia,
            @Parameter(description = "Tipo de aviso") @RequestParam(required = false) TipoAviso tipo,
            @Parameter(description = "true: solo vigentes (no ha llegado la fecha de restablecimiento); false: solo vencidos")
            @RequestParam(required = false) Boolean vigentes) {
        List<AvisoResponse> avisos = avisoService.listar(new AvisoFiltro(zona, colonia, tipo, vigentes));
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + avisos.size() + " avisos", avisos));
    }

    @Operation(summary = "Detalle de un aviso", description = "Público. 404 si no existe.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AvisoResponse>> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok("Aviso encontrado", avisoService.obtener(id)));
    }

    @Operation(summary = "Editar un aviso", description = "Rol ADMIN. Reemplaza todos los campos; conserva el autor.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AvisoResponse>> actualizar(@PathVariable Long id,
                                                                 @Valid @RequestBody AvisoRequest request) {
        return ResponseEntity.ok(ApiResponse.ok("Aviso actualizado correctamente", avisoService.actualizar(id, request)));
    }

    @Operation(summary = "Eliminar un aviso", description = "Rol ADMIN.")
    @SecurityRequirement(name = OpenApiConfig.BEARER)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable Long id) {
        avisoService.eliminar(id);
        return ResponseEntity.ok(ApiResponse.ok("Aviso eliminado correctamente", null));
    }
}
