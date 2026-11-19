package com.cuidagua.api.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.Map;

/**
 * Formato único de respuesta para la app Flutter.
 * <ul>
 *   <li>Éxito: {@code { "exito": true, "mensaje": "...", "datos": ... }}</li>
 *   <li>Error: {@code { "exito": false, "mensaje": "...", "errores": { "campo": "motivo" } }}</li>
 * </ul>
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(boolean exito, String mensaje, T datos, Map<String, String> errores) {

    public static <T> ApiResponse<T> ok(String mensaje, T datos) {
        return new ApiResponse<>(true, mensaje, datos, null);
    }

    public static ApiResponse<Void> error(String mensaje, Map<String, String> errores) {
        return new ApiResponse<>(false, mensaje, null, errores == null ? Map.of() : errores);
    }
}
