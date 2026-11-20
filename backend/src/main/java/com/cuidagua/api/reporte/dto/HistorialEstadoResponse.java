package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.HistorialEstado;

import java.time.LocalDateTime;

/** Un cambio de estado. {@code estadoAnterior} es null en el registro inicial del reporte. */
public record HistorialEstadoResponse(
        Integer id,
        EstadoReporte estadoAnterior,
        EstadoReporte estadoNuevo,
        String observacion,
        String responsable,
        LocalDateTime fecha
) {

    public static HistorialEstadoResponse desde(HistorialEstado historial) {
        return new HistorialEstadoResponse(
                historial.getId(),
                historial.getEstadoAnterior(),
                historial.getEstadoNuevo(),
                historial.getObservacion(),
                historial.getResponsable() == null ? null : historial.getResponsable().getNombre(),
                historial.getFecha());
    }
}
