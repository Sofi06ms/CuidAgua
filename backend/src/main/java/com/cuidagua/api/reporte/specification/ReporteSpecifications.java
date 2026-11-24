package com.cuidagua.api.reporte.specification;

import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.entity.Reporte;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

/** Construye la consulta dinámica de reportes a partir de los filtros recibidos. */
public final class ReporteSpecifications {

    private ReporteSpecifications() {
    }

    public static Specification<Reporte> conFiltro(ReporteFiltro filtro) {
        return (root, query, cb) -> {
            List<Predicate> condiciones = new ArrayList<>();
            if (filtro.estado() != null) {
                condiciones.add(cb.equal(root.get("estado"), filtro.estado()));
            }
            if (filtro.categoria() != null) {
                condiciones.add(cb.equal(root.get("categoria"), filtro.categoria()));
            }
            if (filtro.zonaId() != null) {
                condiciones.add(cb.equal(root.get("zona").get("id"), filtro.zonaId()));
            }
            return cb.and(condiciones.toArray(Predicate[]::new));
        };
    }
}
