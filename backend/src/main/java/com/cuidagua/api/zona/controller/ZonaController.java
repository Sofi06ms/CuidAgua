package com.cuidagua.api.zona.controller;

import com.cuidagua.api.common.dto.ApiResponse;
import com.cuidagua.api.zona.dto.ZonaResponse;
import com.cuidagua.api.zona.service.ZonaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Zonas", description = "Catálogo de zonas de la ciudad")
@RestController
@RequestMapping("/api/zonas")
@RequiredArgsConstructor
public class ZonaController {

    private final ZonaService zonaService;

    @Operation(summary = "Listar zonas",
            description = "Público. Usa el id de la zona en zonaId al crear reportes o avisos y en los filtros.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<ZonaResponse>>> listar() {
        List<ZonaResponse> zonas = zonaService.listar();
        return ResponseEntity.ok(ApiResponse.ok("Se encontraron " + zonas.size() + " zonas", zonas));
    }
}
