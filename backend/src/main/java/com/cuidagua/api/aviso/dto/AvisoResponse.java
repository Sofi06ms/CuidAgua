package com.cuidagua.api.aviso.dto;

import com.cuidagua.api.aviso.entity.Aviso;
import com.cuidagua.api.aviso.entity.TipoAviso;

import java.time.LocalDateTime;

/** Datos de un aviso que devuelve la API. */
public record AvisoResponse(
        Long id,
        String titulo,
        String mensaje,
        String colonia,
        TipoAviso tipo,
        LocalDateTime fechaInicio,
        LocalDateTime fechaRestablecimiento,
        String creadoPor,
        LocalDateTime fechaCreacion
) {

    public static AvisoResponse desde(Aviso aviso) {
        return new AvisoResponse(
                aviso.getId(),
                aviso.getTitulo(),
                aviso.getMensaje(),
                aviso.getColonia(),
                aviso.getTipo(),
                aviso.getFechaInicio(),
                aviso.getFechaRestablecimiento(),
                aviso.getCreadoPorNombre(),
                aviso.getFechaCreacion());
    }
}
