package com.cuidagua.api.aviso.dto;

import com.cuidagua.api.aviso.entity.Aviso;
import com.cuidagua.api.aviso.entity.TipoAviso;
import com.cuidagua.api.zona.dto.ZonaResponse;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Datos de un aviso que devuelve la API. {@code zona} es null en los avisos generales.
 * {@code horario} es un texto legible calculado de fechaInicio y fechaRestablecimiento (ver {@link HorarioAviso}).
 */
public record AvisoResponse(
        Integer id,
        String titulo,
        String mensaje,
        ZonaResponse zona,
        TipoAviso tipo,
        LocalDateTime fechaInicio,
        LocalDateTime fechaRestablecimiento,
        String horario,
        boolean vigente,
        String creadoPor,
        LocalDateTime fechaPublicacion,
        LocalDateTime fechaActualizacion
) {

    public static AvisoResponse desde(Aviso aviso) {
        return new AvisoResponse(
                aviso.getId(),
                aviso.getTitulo(),
                aviso.getMensaje(),
                ZonaResponse.desde(aviso.getZona()),
                aviso.getTipo(),
                aviso.getFechaInicio(),
                aviso.getFechaRestablecimiento(),
                HorarioAviso.describir(aviso.getFechaInicio(), aviso.getFechaRestablecimiento(),
                        LocalDate.now().getYear()),
                aviso.estaVigente(LocalDateTime.now()),
                aviso.getCreadoPor().getNombre(),
                aviso.getFechaPublicacion(),
                aviso.getFechaActualizacion());
    }
}
