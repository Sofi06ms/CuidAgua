package com.cuidagua.api.usuario.entity;

import com.cuidagua.api.common.catalogo.CatalogoJpaConverter;
import jakarta.persistence.Converter;

/** Guarda {@link RolUsuario} con su valor en minúsculas. */
@Converter
public class RolUsuarioConverter extends CatalogoJpaConverter<RolUsuario> {

    public RolUsuarioConverter() {
        super(RolUsuario.class);
    }
}
