package com.cuidagua.api.aviso.entity;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import com.fasterxml.jackson.annotation.JsonValue;

/** Tipos de aviso sobre el suministro de agua (columna avisos.tipo, agregada en V2). */
public enum TipoAviso implements ValorCatalogo {
    CORTE("corte"),
    RESTABLECIMIENTO("restablecimiento"),
    MANTENIMIENTO("mantenimiento"),
    BAJA_PRESION("baja_presion");

    private final String valor;

    TipoAviso(String valor) {
        this.valor = valor;
    }

    @Override
    @JsonValue
    public String getValor() {
        return valor;
    }

    @Override
    public String toString() {
        return valor;
    }
}
