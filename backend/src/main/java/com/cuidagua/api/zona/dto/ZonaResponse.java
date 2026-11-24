package com.cuidagua.api.zona.dto;

import com.cuidagua.api.zona.entity.Zona;

/** Zona tal como la devuelve la API. */
public record ZonaResponse(Integer id, String nombre) {

    /** null si la zona es null (reportes o avisos sin zona). */
    public static ZonaResponse desde(Zona zona) {
        return zona == null ? null : new ZonaResponse(zona.getId(), zona.getNombreZona());
    }
}
