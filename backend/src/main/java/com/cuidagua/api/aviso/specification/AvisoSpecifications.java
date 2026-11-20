package com.cuidagua.api.aviso.specification;

import com.cuidagua.api.aviso.dto.AvisoFiltro;
import com.cuidagua.api.aviso.entity.Aviso;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** Construye la consulta dinámica de avisos a partir de los filtros recibidos. */
public final class AvisoSpecifications {

    private AvisoSpecifications() {
    }

    public static Specification<Aviso> conFiltro(AvisoFiltro filtro, LocalDateTime ahora) {
        return (root, query, cb) -> {
            List<Predicate> condiciones = new ArrayList<>();
            if (filtro.zonaId() != null) {
                condiciones.add(cb.equal(root.get("zona").get("id"), filtro.zonaId()));
            }
            if (filtro.tipo() != null) {
                condiciones.add(cb.equal(root.get("tipo"), filtro.tipo()));
            }
            if (Boolean.TRUE.equals(filtro.vigentes())) {
                condiciones.add(cb.greaterThan(root.get("fechaRestablecimiento"), ahora));
            } else if (Boolean.FALSE.equals(filtro.vigentes())) {
                condiciones.add(cb.lessThanOrEqualTo(root.get("fechaRestablecimiento"), ahora));
            }
            return cb.and(condiciones.toArray(Predicate[]::new));
        };
    }
}
