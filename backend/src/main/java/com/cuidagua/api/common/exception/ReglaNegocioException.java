package com.cuidagua.api.common.exception;

import lombok.Getter;

/**
 * Error de validación que no se puede expresar con anotaciones
 * (por ejemplo, comparar dos campos). Se responde con 400.
 */
@Getter
public class ReglaNegocioException extends RuntimeException {

    private final String campo;

    public ReglaNegocioException(String campo, String mensaje) {
        super(mensaje);
        this.campo = campo;
    }
}
