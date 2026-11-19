package com.cuidagua.api.common.exception;

import lombok.Getter;

/**
 * La operación no es posible por el estado actual del recurso
 * (por ejemplo, cambiar el estado de un reporte ya RESUELTO). Se responde con 409.
 */
@Getter
public class ConflictoException extends RuntimeException {

    private final String campo;

    public ConflictoException(String campo, String mensaje) {
        super(mensaje);
        this.campo = campo;
    }
}
