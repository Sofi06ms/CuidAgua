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
        String zona,
        TipoAviso tipo,
        LocalDateTime fechaInicio,
        LocalDateTime fechaRestablecimiento,
        boolean vigente,
        String creadoPor,
        LocalDateTime fechaCreacion,
        LocalDateTime fechaActualizacion
) {

    public static AvisoResponse desde(Aviso aviso) {
        return new AvisoResponse(
                aviso.getId(),
                aviso.getTitulo(),
                aviso.getMensaje(),
                aviso.getColonia(),
                aviso.getZona(),
                aviso.getTipo(),
                aviso.getFechaInicio(),
                aviso.getFechaRestablecimiento(),
                aviso.estaVigente(LocalDateTime.now()),
                aviso.getCreadoPorNombre(),
                aviso.getFechaCreacion(),
                aviso.getFechaActualizacion());
    }
}
