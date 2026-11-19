package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.TipoReporte;

import java.util.Map;

/** Conteos para el tablero del panel administrativo. Incluye todos los estados y tipos, aunque valgan 0. */
public record ResumenReportesResponse(
        long total,
        Map<EstadoReporte, Long> porEstado,
        Map<TipoReporte, Long> porTipo
) {
}
