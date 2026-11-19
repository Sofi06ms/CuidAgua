package com.cuidagua.api.reporte.repository;

import com.cuidagua.api.reporte.entity.Reporte;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ReporteRepository extends JpaRepository<Reporte, Long>, JpaSpecificationExecutor<Reporte> {

    List<Reporte> findByUsuarioIdOrderByFechaCreacionDescIdDesc(String usuarioId);

    /** Filas [EstadoReporte, Long]. */
    @Query("select r.estado, count(r) from Reporte r group by r.estado")
    List<Object[]> contarPorEstado();

    /** Filas [TipoReporte, Long]. */
    @Query("select r.tipo, count(r) from Reporte r group by r.tipo")
    List<Object[]> contarPorTipo();
}
