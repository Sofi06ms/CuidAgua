package com.cuidagua.api.reporte.converter;

import com.cuidagua.api.common.catalogo.CatalogoJpaConverter;
import com.cuidagua.api.reporte.entity.CategoriaReporte;
import jakarta.persistence.Converter;

/** Guarda {@link CategoriaReporte} con su valor en minúsculas. */
@Converter
public class CategoriaReporteConverter extends CatalogoJpaConverter<CategoriaReporte> {

    public CategoriaReporteConverter() {
        super(CategoriaReporte.class);
    }
}
