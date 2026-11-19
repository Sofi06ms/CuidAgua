package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.reporte.entity.TipoReporte;

import java.time.LocalDateTime;

/** Datos de un reporte que devuelve la API. */
public record ReporteResponse(
        Long id,
        TipoReporte tipo,
        String descripcion,
        String direccion,
        String colonia,
        String zona,
        Double latitud,
        Double longitud,
        String fotoUrl,
        EstadoReporte estado,
        String usuario,
        LocalDateTime fechaCreacion,
        String comentarioEstado,
        String actualizadoPor,
        LocalDateTime fechaActualizacion
) {

    public static ReporteResponse desde(Reporte reporte) {
        return new ReporteResponse(
                reporte.getId(),
                reporte.getTipo(),
                reporte.getDescripcion(),
                reporte.getDireccion(),
                reporte.getColonia(),
                reporte.getZona(),
                reporte.getLatitud(),
                reporte.getLongitud(),
                reporte.getFotoUrl(),
                reporte.getEstado(),
                reporte.getUsuarioNombre(),
                reporte.getFechaCreacion(),
                reporte.getComentarioEstado(),
                reporte.getActualizadoPor(),
                reporte.getFechaActualizacion());
    }
}
