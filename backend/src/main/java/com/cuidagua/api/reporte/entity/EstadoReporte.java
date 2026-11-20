package com.cuidagua.api.reporte.entity;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import com.fasterxml.jackson.annotation.JsonValue;

import java.util.EnumSet;
import java.util.Set;

/**
 * Estados del ciclo de vida de un reporte (columna reportes.estado). Todo reporte nuevo inicia en "pendiente".
 *
 * <pre>
 * pendiente   -> en_revision | resuelto | rechazado
 * en_revision -> resuelto | rechazado
 * resuelto, rechazado: estados finales
 * </pre>
 */
public enum EstadoReporte implements ValorCatalogo {
    PENDIENTE("pendiente"),
    EN_REVISION("en_revision"),
    RESUELTO("resuelto"),
    RECHAZADO("rechazado");

    private final String valor;

    EstadoReporte(String valor) {
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

    /** Estados a los que se puede pasar desde este. */
    public Set<EstadoReporte> siguientesPermitidos() {
        return switch (this) {
            case PENDIENTE -> EnumSet.of(EN_REVISION, RESUELTO, RECHAZADO);
            case EN_REVISION -> EnumSet.of(RESUELTO, RECHAZADO);
            case RESUELTO, RECHAZADO -> EnumSet.noneOf(EstadoReporte.class);
        };
    }

    public boolean puedeCambiarA(EstadoReporte nuevo) {
        return siguientesPermitidos().contains(nuevo);
    }

    public boolean esFinal() {
        return siguientesPermitidos().isEmpty();
    }
}
