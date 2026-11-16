package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.TipoReporte;

/**
 * Filtros opcionales para consultar reportes. Un campo null no filtra.
 * {@code zona} y {@code colonia} se comparan sin distinguir mayúsculas.
 */
public record ReporteFiltro(EstadoReporte estado, TipoReporte tipo, String zona, String colonia) {

    public static ReporteFiltro sinFiltros() {
        return new ReporteFiltro(null, null, null, null);
    }
}
