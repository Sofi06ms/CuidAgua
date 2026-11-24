package com.cuidagua.api.aviso.dto;

import com.cuidagua.api.aviso.entity.TipoAviso;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

/** Datos que envía un administrador para publicar o editar un aviso de suministro. */
public record AvisoRequest(

        @NotBlank(message = "El título es obligatorio")
        @Size(min = 5, max = 150, message = "El título debe tener entre 5 y 150 caracteres")
        String titulo,

        @NotBlank(message = "El mensaje es obligatorio")
        @Size(min = 10, max = 1000, message = "El mensaje debe tener entre 10 y 1000 caracteres")
        String mensaje,

        /* Opcional: si no se envía, el aviso es general para toda la ciudad. */
        @Positive(message = "El id de la zona no es válido")
        Integer zonaId,

        @NotNull(message = "El tipo de aviso es obligatorio")
        TipoAviso tipo,

        /* Opcional: si no se envía, el aviso aplica desde que se publica. */
        LocalDateTime fechaInicio,

        @NotNull(message = "La fecha de restablecimiento es obligatoria")
        @Future(message = "La fecha de restablecimiento debe ser una fecha futura")
        LocalDateTime fechaRestablecimiento
) {
}
