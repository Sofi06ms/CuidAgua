package com.cuidagua.api.aviso.repository;

import com.cuidagua.api.aviso.entity.Aviso;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface AvisoRepository extends JpaRepository<Aviso, Long>, JpaSpecificationExecutor<Aviso> {
}
