package com.cuidagua.api.reporte.dto;

import com.cuidagua.api.reporte.entity.TipoReporte;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.URL;

/** Datos que envía la app para registrar una incidencia. */
public record ReporteRequest(

        @NotNull(message = "El tipo de reporte es obligatorio")
        TipoReporte tipo,

        @NotBlank(message = "La descripción es obligatoria")
        @Size(min = 10, max = 500, message = "La descripción debe tener entre 10 y 500 caracteres")
        String descripcion,

        @NotBlank(message = "La dirección es obligatoria")
        @Size(max = 255, message = "La dirección no puede superar los 255 caracteres")
        String direccion,

        @NotBlank(message = "La colonia es obligatoria")
        @Size(max = 120, message = "La colonia no puede superar los 120 caracteres")
        String colonia,

        @DecimalMin(value = "-90.0", message = "La latitud debe estar entre -90 y 90")
        @DecimalMax(value = "90.0", message = "La latitud debe estar entre -90 y 90")
        Double latitud,

        @DecimalMin(value = "-180.0", message = "La longitud debe estar entre -180 y 180")
        @DecimalMax(value = "180.0", message = "La longitud debe estar entre -180 y 180")
        Double longitud,

        @Size(max = 500, message = "La URL de la foto no puede superar los 500 caracteres")
        @URL(message = "La URL de la foto no es válida")
        String fotoUrl
) {
}
