package com.cuidagua.api.common.catalogo;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Enum cuyo valor en la base de datos y en el JSON es un texto en minúsculas
 * definido en el diseño oficial de la BD (ej. "pendiente", "tuberia_danada").
 * <p>
 * Cada enum devuelve ese valor en {@code toString()} para que los mensajes de error
 * muestren los valores que realmente acepta la API.
 */
public interface ValorCatalogo {

    /** Valor guardado en la BD y usado en el JSON. */
    String getValor();

    /**
     * Busca la constante del enum cuyo valor coincide (sin distinguir mayúsculas).
     *
     * @throws IllegalArgumentException si el valor no existe
     */
    static <E extends Enum<E> & ValorCatalogo> E desde(Class<E> tipo, String valor) {
        for (E constante : tipo.getEnumConstants()) {
            if (constante.getValor().equalsIgnoreCase(valor.trim())) {
                return constante;
            }
        }
        throw new IllegalArgumentException("Valor '" + valor + "' no válido. Valores permitidos: " + valores(tipo));
    }

    static String valores(Class<?> tipo) {
        return Arrays.stream(tipo.getEnumConstants()).map(Object::toString).collect(Collectors.joining(", "));
    }
}
