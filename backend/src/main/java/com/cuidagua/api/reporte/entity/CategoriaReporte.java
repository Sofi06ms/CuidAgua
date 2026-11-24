package com.cuidagua.api.reporte.entity;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import com.fasterxml.jackson.annotation.JsonValue;

/** Categorías de incidencia que un ciudadano puede reportar (columna reportes.categoria). */
public enum CategoriaReporte implements ValorCatalogo {
    FUGA("fuga"),
    TUBERIA_DANADA("tuberia_danada"),
    FALTA_SUMINISTRO("falta_suministro"),
    BAJA_PRESION("baja_presion"),
    OTRO("otro");

    private final String valor;

    CategoriaReporte(String valor) {
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
