package com.cuidagua.api.common.util;

/**
 * Utilidades pequeñas para limpiar textos recibidos de la app.
 */
public final class TextoUtils {

    private TextoUtils() {
    }

    /** Quita espacios al inicio y al final; devuelve null si queda vacío. */
    public static String limpiar(String valor) {
        if (valor == null) {
            return null;
        }
        String limpio = valor.trim();
        return limpio.isEmpty() ? null : limpio;
    }
}
