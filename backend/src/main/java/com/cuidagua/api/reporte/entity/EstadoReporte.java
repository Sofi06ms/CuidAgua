package com.cuidagua.api.reporte.entity;

/** Estados del ciclo de vida de un reporte. Todo reporte nuevo inicia en PENDIENTE. */
public enum EstadoReporte {
    PENDIENTE,
    EN_PROCESO,
    RESUELTO,
    RECHAZADO
}
