package com.cuidagua.api.reporte.entity;

import com.cuidagua.api.reporte.converter.EstadoReporteConverter;
import com.cuidagua.api.usuario.entity.Usuario;
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
 * Registro de cada cambio de estado de un reporte (tabla "historial_estados").
 * La primera fila de cada reporte tiene estado_anterior = null y estado_nuevo = pendiente.
 */
@Entity
@Table(name = "historial_estados")
@Getter
@Setter
@NoArgsConstructor
public class HistorialEstado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reporte_id", nullable = false)
    private Reporte reporte;

    @Convert(converter = EstadoReporteConverter.class)
    @Column(name = "estado_anterior", length = 30)
    private EstadoReporte estadoAnterior;

    @Convert(converter = EstadoReporteConverter.class)
    @Column(name = "estado_nuevo", nullable = false, length = 30)
    private EstadoReporte estadoNuevo;

    @Column(columnDefinition = "TEXT")
    private String observacion;

    /** Quien hizo el cambio (el ciudadano en el registro inicial, personal o administrador después). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "responsable_id")
    private Usuario responsable;

    @Column(name = "fecha")
    private LocalDateTime fecha;

    @PrePersist
    void alCrear() {
        if (fecha == null) {
            fecha = LocalDateTime.now();
        }
    }
}
