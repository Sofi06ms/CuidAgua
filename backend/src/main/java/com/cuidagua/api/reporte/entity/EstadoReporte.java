package com.cuidagua.api.reporte.entity;

import java.util.EnumSet;
import java.util.Set;

/**
 * Estados del ciclo de vida de un reporte. Todo reporte nuevo inicia en PENDIENTE.
 *
 * <pre>
 * PENDIENTE  -> EN_PROCESO | RESUELTO | RECHAZADO
 * EN_PROCESO -> RESUELTO | RECHAZADO
 * RESUELTO, RECHAZADO: estados finales
 * </pre>
 */
public enum EstadoReporte {
    PENDIENTE,
    EN_PROCESO,
    RESUELTO,
    RECHAZADO;

    /** Estados a los que se puede pasar desde este. */
    public Set<EstadoReporte> siguientesPermitidos() {
        return switch (this) {
            case PENDIENTE -> EnumSet.of(EN_PROCESO, RESUELTO, RECHAZADO);
            case EN_PROCESO -> EnumSet.of(RESUELTO, RECHAZADO);
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
