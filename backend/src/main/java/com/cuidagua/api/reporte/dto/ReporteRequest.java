package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.CategoriaReporte;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.URL;

import java.math.BigDecimal;
import java.util.List;

/** Datos que envía la app para registrar una incidencia. */
public record ReporteRequest(

        @NotNull(message = "La categoría es obligatoria")
        CategoriaReporte categoria,

        @NotBlank(message = "La descripción es obligatoria")
        @Size(min = 10, max = 500, message = "La descripción debe tener entre 10 y 500 caracteres")
        String descripcion,

        @NotNull(message = "La zona es obligatoria")
        @Positive(message = "El id de la zona no es válido")
        Integer zonaId,

        @DecimalMin(value = "-90.0", message = "La latitud debe estar entre -90 y 90")
        @DecimalMax(value = "90.0", message = "La latitud debe estar entre -90 y 90")
        BigDecimal latitud,

        @DecimalMin(value = "-180.0", message = "La longitud debe estar entre -180 y 180")
        @DecimalMax(value = "180.0", message = "La longitud debe estar entre -180 y 180")
        BigDecimal longitud,

        /* Opcional: URLs de las fotos (tabla evidencias). */
        @Size(max = 5, message = "Se permiten como máximo 5 evidencias")
        List<@NotBlank(message = "La URL de la evidencia no puede estar vacía")
             @Size(max = 255, message = "La URL de la evidencia no puede superar los 255 caracteres")
             @URL(message = "La URL de la evidencia no es válida") String> evidencias
) {
}
