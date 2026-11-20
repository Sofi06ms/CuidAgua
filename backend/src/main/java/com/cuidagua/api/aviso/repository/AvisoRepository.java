package com.cuidagua.api.aviso.repository;

import com.cuidagua.api.aviso.entity.Aviso;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface AvisoRepository extends JpaRepository<Aviso, Integer>, JpaSpecificationExecutor<Aviso> {

    /** Trae zona y autor en la misma consulta. */
    @Override
    @EntityGraph(attributePaths = {"zona", "creadoPor"})
    List<Aviso> findAll(Specification<Aviso> spec, Sort sort);
}
