package com.cuidagua.api.aviso.dto;

import com.cuidagua.api.aviso.entity.TipoAviso;

/**
 * Filtros opcionales para consultar avisos. Un campo null no filtra.
 * {@code zona} y {@code colonia} se comparan sin distinguir mayúsculas.
 *
 * @param vigentes true: solo avisos cuya fecha de restablecimiento no ha pasado;
 *                 false: solo los ya vencidos
 */
public record AvisoFiltro(String zona, String colonia, TipoAviso tipo, Boolean vigentes) {

    public static AvisoFiltro sinFiltros() {
        return new AvisoFiltro(null, null, null, null);
    }
}
