package com.cuidagua.api.common.exception;

import com.cuidagua.api.common.dto.ApiResponse;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.temporal.Temporal;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Convierte las excepciones en respuestas JSON con el formato {@link ApiResponse}.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String MSG_VALIDACION = "Los datos enviados no son válidos";

    /** Errores de las anotaciones de validación (@NotBlank, @Size, etc.). */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> manejarValidacion(MethodArgumentNotValidException ex) {
        Map<String, String> errores = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            errores.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        ex.getBindingResult().getGlobalErrors()
                .forEach(error -> errores.putIfAbsent(error.getObjectName(), error.getDefaultMessage()));
        return respuesta(HttpStatus.BAD_REQUEST, MSG_VALIDACION, errores);
    }

    /** Reglas que comparan varios campos (ej. fechaInicio antes de fechaRestablecimiento). */
    @ExceptionHandler(ReglaNegocioException.class)
    public ResponseEntity<ApiResponse<Void>> manejarReglaNegocio(ReglaNegocioException ex) {
        return respuesta(HttpStatus.BAD_REQUEST, MSG_VALIDACION, Map.of(ex.getCampo(), ex.getMessage()));
    }

    /** JSON mal formado, valores de enum desconocidos o fechas con formato incorrecto. */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> manejarJsonInvalido(HttpMessageNotReadableException ex) {
        if (ex.getCause() instanceof MismatchedInputException mie && !mie.getPath().isEmpty()) {
            String campo = rutaCampo(mie);
            return respuesta(HttpStatus.BAD_REQUEST, MSG_VALIDACION, Map.of(campo, motivoFormato(mie)));
        }
        return respuesta(HttpStatus.BAD_REQUEST, "El cuerpo de la solicitud no es un JSON válido",
                Map.of("body", "Revisa que el JSON esté bien formado"));
    }

    /** Parámetros de URL con tipo incorrecto. */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Void>> manejarTipoParametro(MethodArgumentTypeMismatchException ex) {
        return respuesta(HttpStatus.BAD_REQUEST, MSG_VALIDACION,
                Map.of(ex.getName(), "El valor '" + ex.getValue() + "' no es válido"));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> manejarNoEncontrado(NoResourceFoundException ex) {
        return respuesta(HttpStatus.NOT_FOUND, "El recurso solicitado no existe",
                Map.of("ruta", "/" + ex.getResourcePath()));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> manejarMetodo(HttpRequestMethodNotSupportedException ex) {
        return respuesta(HttpStatus.METHOD_NOT_ALLOWED, "Método HTTP no permitido en esta ruta",
                Map.of("metodo", ex.getMethod()));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> manejarMediaType(HttpMediaTypeNotSupportedException ex) {
        return respuesta(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Tipo de contenido no soportado",
                Map.of("Content-Type", "Usa application/json"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> manejarGeneral(Exception ex) {
        log.error("Error no controlado", ex);
        return respuesta(HttpStatus.INTERNAL_SERVER_ERROR, "Ocurrió un error interno en el servidor", Map.of());
    }

    private ResponseEntity<ApiResponse<Void>> respuesta(HttpStatus status, String mensaje, Map<String, String> errores) {
        return ResponseEntity.status(status).body(ApiResponse.error(mensaje, errores));
    }

    private String rutaCampo(MismatchedInputException ex) {
        return ex.getPath().stream()
                .map(ref -> ref.getFieldName() != null ? ref.getFieldName() : "[" + ref.getIndex() + "]")
                .collect(Collectors.joining("."));
    }

    private String motivoFormato(MismatchedInputException ex) {
        Class<?> tipo = ex.getTargetType();
        if (tipo != null && tipo.isEnum()) {
            String permitidos = Arrays.stream(tipo.getEnumConstants())
                    .map(Object::toString)
                    .collect(Collectors.joining(", "));
            return "Valor no válido. Valores permitidos: " + permitidos;
        }
        if (tipo != null && Temporal.class.isAssignableFrom(tipo)) {
            return "Formato de fecha no válido. Usa yyyy-MM-ddTHH:mm:ss (ej. 2026-11-20T08:00:00)";
        }
        return "El valor tiene un formato o tipo incorrecto";
    }
}
