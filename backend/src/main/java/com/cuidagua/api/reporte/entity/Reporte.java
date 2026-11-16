package com.cuidagua.api.reporte.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/** Incidencia reportada por un ciudadano (tabla "reportes"). */
@Entity
@Table(name = "reportes")
@Getter
@Setter
@NoArgsConstructor
public class Reporte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoReporte tipo;

    @Column(nullable = false, length = 500)
    private String descripcion;

    @Column(nullable = false, length = 255)
    private String direccion;

    @Column(nullable = false, length = 120)
    private String colonia;

    /** Zona o sector de la ciudad; se usa para filtrar. NULL solo en registros anteriores a V2. */
    @Column(length = 80)
    private String zona;

    private Double latitud;

    private Double longitud;

    @Column(name = "foto_url", length = 500)
    private String fotoUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoReporte estado;

    /** Identificador del usuario en Keycloak (claim "sub"). */
    @Column(name = "usuario_id", nullable = false, length = 64)
    private String usuarioId;

    /** Nombre de usuario en Keycloak (claim "preferred_username"). */
    @Column(name = "usuario_nombre", nullable = false, length = 255)
    private String usuarioNombre;

    @Column(name = "fecha_creacion", nullable = false, updatable = false)
    private LocalDateTime fechaCreacion;

    /** Comentario del administrador en el último cambio de estado (obligatorio al rechazar). */
    @Column(name = "comentario_estado", length = 500)
    private String comentarioEstado;

    /** Administrador (preferred_username) que hizo el último cambio de estado. */
    @Column(name = "actualizado_por", length = 255)
    private String actualizadoPor;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @PrePersist
    void alCrear() {
        if (estado == null) {
            estado = EstadoReporte.PENDIENTE;
        }
        if (fechaCreacion == null) {
            fechaCreacion = LocalDateTime.now();
        }
    }
}
