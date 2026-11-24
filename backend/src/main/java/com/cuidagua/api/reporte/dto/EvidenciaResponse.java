package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.Evidencia;

import java.time.LocalDateTime;

public record EvidenciaResponse(Integer id, String url, LocalDateTime fechaCarga) {

    public static EvidenciaResponse desde(Evidencia evidencia) {
        return new EvidenciaResponse(evidencia.getId(), evidencia.getUrlArchivo(), evidencia.getFechaCarga());
    }
}
