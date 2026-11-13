package com.cuidagua.api.reporte.repository;

import com.cuidagua.api.reporte.entity.Reporte;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReporteRepository extends JpaRepository<Reporte, Long> {

    List<Reporte> findAllByOrderByFechaCreacionDescIdDesc();

    List<Reporte> findByColoniaIgnoreCaseOrderByFechaCreacionDescIdDesc(String colonia);
}
