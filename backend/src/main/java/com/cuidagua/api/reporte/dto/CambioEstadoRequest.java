package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Datos que envía el panel administrativo para cambiar el estado de un reporte. */
public record CambioEstadoRequest(

        @NotNull(message = "El estado es obligatorio")
        EstadoReporte estado,

        /* Opcional, salvo al pasar a RECHAZADO (se valida en el servicio). */
        @Size(max = 500, message = "El comentario no puede superar los 500 caracteres")
        String comentario
) {
}
