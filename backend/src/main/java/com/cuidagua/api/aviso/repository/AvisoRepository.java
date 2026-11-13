package com.cuidagua.api.aviso.repository;

import com.cuidagua.api.aviso.entity.Aviso;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AvisoRepository extends JpaRepository<Aviso, Long> {

    List<Aviso> findAllByOrderByFechaCreacionDescIdDesc();

    List<Aviso> findByColoniaIgnoreCaseOrderByFechaCreacionDescIdDesc(String colonia);
}
