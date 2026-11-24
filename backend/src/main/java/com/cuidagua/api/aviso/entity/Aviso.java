package com.cuidagua.api.aviso.entity;

import com.cuidagua.api.aviso.converter.TipoAvisoConverter;
import com.cuidagua.api.usuario.entity.Usuario;
import com.cuidagua.api.zona.entity.Zona;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Aviso de suministro publicado por un administrador (tabla "avisos").
 * tipo, fechaInicio, fechaRestablecimiento, creadoPor y fechaActualizacion se agregaron en V2.
 */
@Entity
@Table(name = "avisos")
@Getter
@Setter
@NoArgsConstructor
public class Aviso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** null = aviso general para toda la ciudad. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zona_id")
    private Zona zona;

    @Column(nullable = false, length = 150)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String mensaje;

    @Column(name = "fecha_publicacion", updatable = false)
    private LocalDateTime fechaPublicacion;

    @Convert(converter = TipoAvisoConverter.class)
    @Column(nullable = false, length = 30)
    private TipoAviso tipo;

    @Column(name = "fecha_inicio")
    private LocalDateTime fechaInicio;

    @Column(name = "fecha_restablecimiento", nullable = false)
    private LocalDateTime fechaRestablecimiento;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "creado_por_id", nullable = false, updatable = false)
    private Usuario creadoPor;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @PrePersist
    void alCrear() {
        if (fechaPublicacion == null) {
            fechaPublicacion = LocalDateTime.now();
        }
    }

    /** Un aviso está vigente mientras no llegue su fecha de restablecimiento. */
    public boolean estaVigente(LocalDateTime ahora) {
        return fechaRestablecimiento.isAfter(ahora);
    }
}
