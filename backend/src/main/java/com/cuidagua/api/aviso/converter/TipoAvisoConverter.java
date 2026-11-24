package com.cuidagua.api.aviso.converter;

import com.cuidagua.api.common.catalogo.CatalogoJpaConverter;
import com.cuidagua.api.aviso.entity.TipoAviso;
import jakarta.persistence.Converter;

/** Guarda {@link TipoAviso} con su valor en minúsculas. */
@Converter
public class TipoAvisoConverter extends CatalogoJpaConverter<TipoAviso> {

    public TipoAvisoConverter() {
        super(TipoAviso.class);
    }
}
