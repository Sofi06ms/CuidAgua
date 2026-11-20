package com.cuidagua.api.reporte.repository;

import com.cuidagua.api.reporte.entity.Reporte;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ReporteRepository extends JpaRepository<Reporte, Integer>, JpaSpecificationExecutor<Reporte> {

    /** Trae usuario y zona en la misma consulta para no hacer una consulta extra por reporte. */
    @Override
    @EntityGraph(attributePaths = {"usuario", "zona"})
    List<Reporte> findAll(Specification<Reporte> spec, Sort sort);

    @EntityGraph(attributePaths = {"usuario", "zona"})
    List<Reporte> findByUsuarioKeycloakIdOrderByFechaCreacionDescIdDesc(String keycloakId);

    /** Siguiente consecutivo para el folio (secuencia creada en V2). */
    @Query(value = "SELECT nextval('folio_reportes_seq')", nativeQuery = true)
    long siguienteConsecutivoFolio();

    /** Filas [EstadoReporte, Long]. */
    @Query("select r.estado, count(r) from Reporte r group by r.estado")
    List<Object[]> contarPorEstado();

    /** Filas [CategoriaReporte, Long]. */
    @Query("select r.categoria, count(r) from Reporte r group by r.categoria")
    List<Object[]> contarPorCategoria();
}
