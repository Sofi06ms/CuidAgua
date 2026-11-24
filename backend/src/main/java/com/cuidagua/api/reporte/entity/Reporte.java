package com.cuidagua.api.reporte.entity;

import com.cuidagua.api.reporte.converter.CategoriaReporteConverter;
import com.cuidagua.api.reporte.converter.EstadoReporteConverter;
import com.cuidagua.api.usuario.entity.Usuario;
import com.cuidagua.api.zona.entity.Zona;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.BatchSize;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** Incidencia reportada por un ciudadano (tabla "reportes"). */
@Entity
@Table(name = "reportes")
@Getter
@Setter
@NoArgsConstructor
public class Reporte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** Identificador público, ej. CA-2026-000001. Lo genera ReporteService. */
    @Column(nullable = false, unique = true, length = 20, updatable = false)
    private String folio;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false, updatable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "zona_id")
    private Zona zona;

    @Convert(converter = CategoriaReporteConverter.class)
    @Column(nullable = false, length = 50)
    private CategoriaReporte categoria;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    @Column(precision = 10, scale = 8)
    private BigDecimal latitud;

    @Column(precision = 11, scale = 8)
    private BigDecimal longitud;

    @Convert(converter = EstadoReporteConverter.class)
    @Column(length = 30)
    private EstadoReporte estado;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    /** Fotos del reporte (tabla "evidencias"). */
    @OneToMany(mappedBy = "reporte", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id")
    @BatchSize(size = 50)
    private List<Evidencia> evidencias = new ArrayList<>();

    public void agregarEvidencia(String urlArchivo) {
        Evidencia evidencia = new Evidencia();
        evidencia.setReporte(this);
        evidencia.setUrlArchivo(urlArchivo);
        evidencias.add(evidencia);
    }

    @PrePersist
    void alCrear() {
        if (estado == null) {
            estado = EstadoReporte.PENDIENTE;
        }
        if (fechaCreacion == null) {
            fechaCreacion = LocalDateTime.now();
        }
        // Igual que el DEFAULT de la tabla: al crear, la última actualización es la creación.
        if (fechaActualizacion == null) {
            fechaActualizacion = fechaCreacion;
        }
    }
}
