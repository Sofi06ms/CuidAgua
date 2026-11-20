package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;

/** Filtros opcionales para consultar reportes. Un campo null no filtra. */
public record ReporteFiltro(EstadoReporte estado, CategoriaReporte categoria, Integer zonaId) {

    public static ReporteFiltro sinFiltros() {
        return new ReporteFiltro(null, null, null);
    }
}
