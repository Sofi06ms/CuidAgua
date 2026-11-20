package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Datos que envía el panel para cambiar el estado de un reporte. Se guarda en historial_estados. */
public record CambioEstadoRequest(

        @NotNull(message = "El estado es obligatorio")
        EstadoReporte estado,

        /* Opcional, salvo al pasar a rechazado (se valida en el servicio). */
        @Size(max = 500, message = "La observación no puede superar los 500 caracteres")
        String observacion
) {
}
