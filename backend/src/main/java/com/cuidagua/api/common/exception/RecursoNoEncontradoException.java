package com.cuidagua.api.common.exception;

/** El recurso pedido (por ejemplo, un reporte por id) no existe. Se responde con 404. */
public class RecursoNoEncontradoException extends RuntimeException {

    public RecursoNoEncontradoException(String mensaje) {
        super(mensaje);
    }
}
