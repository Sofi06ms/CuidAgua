package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.zona.dto.ZonaResponse;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** Datos de un reporte que devuelve la API. {@code usuario} es el nombre de quien lo registró. */
public record ReporteResponse(
        Integer id,
        String folio,
        CategoriaReporte categoria,
        String descripcion,
        ZonaResponse zona,
        BigDecimal latitud,
        BigDecimal longitud,
        EstadoReporte estado,
        String usuario,
        List<EvidenciaResponse> evidencias,
        LocalDateTime fechaCreacion,
        LocalDateTime fechaActualizacion
) {

    public static ReporteResponse desde(Reporte reporte) {
        return new ReporteResponse(
                reporte.getId(),
                reporte.getFolio(),
                reporte.getCategoria(),
                reporte.getDescripcion(),
                ZonaResponse.desde(reporte.getZona()),
                reporte.getLatitud(),
                reporte.getLongitud(),
                reporte.getEstado(),
                reporte.getUsuario().getNombre(),
                reporte.getEvidencias().stream().map(EvidenciaResponse::desde).toList(),
                reporte.getFechaCreacion(),
                reporte.getFechaActualizacion());
    }
}
