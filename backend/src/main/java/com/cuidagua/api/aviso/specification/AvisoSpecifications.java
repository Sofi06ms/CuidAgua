package com.cuidagua.api.aviso.specification;

import com.cuidagua.api.aviso.dto.AvisoFiltro;
import com.cuidagua.api.aviso.entity.Aviso;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Construye la consulta dinámica de avisos a partir de los filtros recibidos. */
public final class AvisoSpecifications {

    private AvisoSpecifications() {
    }

    public static Specification<Aviso> conFiltro(AvisoFiltro filtro, LocalDateTime ahora) {
        return (root, query, cb) -> {
            List<Predicate> condiciones = new ArrayList<>();
            if (filtro.zona() != null) {
                condiciones.add(cb.equal(cb.lower(root.get("zona")), filtro.zona().toLowerCase(Locale.ROOT)));
            }
            if (filtro.colonia() != null) {
                condiciones.add(cb.equal(cb.lower(root.get("colonia")), filtro.colonia().toLowerCase(Locale.ROOT)));
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
