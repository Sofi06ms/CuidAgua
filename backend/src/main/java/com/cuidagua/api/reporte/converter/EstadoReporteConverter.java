package com.cuidagua.api.reporte.converter;

import com.cuidagua.api.common.catalogo.CatalogoJpaConverter;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import jakarta.persistence.Converter;

/** Guarda {@link EstadoReporte} con su valor en minúsculas. */
@Converter
public class EstadoReporteConverter extends CatalogoJpaConverter<EstadoReporte> {

    public EstadoReporteConverter() {
        super(EstadoReporte.class);
    }
}
