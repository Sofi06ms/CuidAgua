package com.cuidagua.api.aviso.controller;

import com.cuidagua.api.aviso.dto.AvisoRequest;
import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.service.AvisoService;
import com.cuidagua.api.common.dto.ApiResponse;
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
@RequestMapping("/api/avisos")
@RequiredArgsConstructor
public class AvisoController {

    private final AvisoService avisoService;

    /** Publica un aviso. Requiere rol ADMIN (regla definida en SecurityConfig). */
    @PostMapping
    public ResponseEntity<ApiResponse<AvisoResponse>> crear(@Valid @RequestBody AvisoRequest request,
                                                            @AuthenticationPrincipal Jwt jwt) {
        String nombre = jwt.getClaimAsString("preferred_username");
        AvisoResponse creado = avisoService.crear(request, jwt.getSubject(), nombre != null ? nombre : jwt.getSubject());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Aviso publicado correctamente", creado));
    }

    /** Consulta pública de avisos de suministro; filtro opcional ?colonia=. */
    @GetMapping
    public ResponseEntity<ApiResponse<List<AvisoResponse>>> listar(
            @RequestParam(required = false) String colonia) {
        List<AvisoResponse> avisos = avisoService.listar(colonia);
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + avisos.size() + " avisos", avisos));
    }
}
