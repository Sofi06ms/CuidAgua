package com.cuidagua.api.aviso.dto;

import com.cuidagua.api.aviso.entity.TipoAviso;

/**
 * Filtros opcionales para consultar avisos. Un campo null no filtra.
 *
 * @param zonaId   solo los avisos de esa zona (no incluye los generales, que no tienen zona)
 * @param vigentes true: solo avisos cuya fecha de restablecimiento no ha pasado;
 *                 false: solo los ya vencidos
 */
public record AvisoFiltro(Integer zonaId, TipoAviso tipo, Boolean vigentes) {

    public static AvisoFiltro sinFiltros() {
        return new AvisoFiltro(null, null, null);
    }
}
