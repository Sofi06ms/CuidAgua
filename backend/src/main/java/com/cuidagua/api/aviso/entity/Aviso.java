package com.cuidagua.api.aviso.entity;

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

/** Aviso de suministro publicado por un administrador (tabla "avisos"). */
@Entity
@Table(name = "avisos")
@Getter
@Setter
@NoArgsConstructor
public class Aviso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String titulo;

    @Column(nullable = false, length = 1000)
    private String mensaje;

    @Column(nullable = false, length = 120)
    private String colonia;

    /** Zona o sector de la ciudad; se usa para filtrar. NULL solo en registros anteriores a V2. */
    @Column(length = 80)
    private String zona;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoAviso tipo;

    @Column(name = "fecha_inicio")
    private LocalDateTime fechaInicio;

    @Column(name = "fecha_restablecimiento", nullable = false)
    private LocalDateTime fechaRestablecimiento;

    /** Identificador en Keycloak (claim "sub") del administrador que creó el aviso. */
    @Column(name = "creado_por_id", nullable = false, length = 64)
    private String creadoPorId;

    /** Nombre de usuario (claim "preferred_username") del administrador. */
    @Column(name = "creado_por_nombre", nullable = false, length = 255)
    private String creadoPorNombre;

    @Column(name = "fecha_creacion", nullable = false, updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @PrePersist
    void alCrear() {
        if (fechaCreacion == null) {
            fechaCreacion = LocalDateTime.now();
        }
    }

    /** Un aviso está vigente mientras no llegue su fecha de restablecimiento. */
    public boolean estaVigente(LocalDateTime ahora) {
        return fechaRestablecimiento.isAfter(ahora);
    }
}
