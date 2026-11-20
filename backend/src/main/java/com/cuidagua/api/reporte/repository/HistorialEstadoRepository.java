package com.cuidagua.api.reporte.repository;

import com.cuidagua.api.reporte.entity.HistorialEstado;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HistorialEstadoRepository extends JpaRepository<HistorialEstado, Integer> {

    /** Del más antiguo al más reciente. */
    @EntityGraph(attributePaths = "responsable")
    List<HistorialEstado> findByReporteIdOrderByFechaAscIdAsc(Integer reporteId);
}
