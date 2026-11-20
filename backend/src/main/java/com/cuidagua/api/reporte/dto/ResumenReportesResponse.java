package com.cuidagua.api.reporte.dto;

import java.util.Map;

/**
 * Conteos para el tablero del panel. Las claves son los valores del catálogo
 * (ej. "pendiente", "fuga") e incluyen todos los estados y categorías, aunque valgan 0.
 */
public record ResumenReportesResponse(
        long total,
        Map<String, Long> porEstado,
        Map<String, Long> porCategoria
) {
}
