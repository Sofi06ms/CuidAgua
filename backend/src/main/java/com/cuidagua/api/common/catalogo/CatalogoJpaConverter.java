package com.cuidagua.api.common.catalogo;

import jakarta.persistence.AttributeConverter;

/** Guarda un {@link ValorCatalogo} en la BD con su valor en minúsculas en lugar del nombre del enum. */
public abstract class CatalogoJpaConverter<E extends Enum<E> & ValorCatalogo> implements AttributeConverter<E, String> {

    private final Class<E> tipo;

    protected CatalogoJpaConverter(Class<E> tipo) {
        this.tipo = tipo;
    }

    @Override
    public String convertToDatabaseColumn(E valor) {
        return valor == null ? null : valor.getValor();
    }

    @Override
    public E convertToEntityAttribute(String valor) {
        return valor == null ? null : ValorCatalogo.desde(tipo, valor);
    }
}
