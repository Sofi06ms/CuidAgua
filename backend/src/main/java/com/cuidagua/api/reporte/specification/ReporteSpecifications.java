package com.cuidagua.api.reporte.specification;

import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.entity.Reporte;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

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
            if (filtro.tipo() != null) {
                condiciones.add(cb.equal(root.get("tipo"), filtro.tipo()));
            }
            if (filtro.zona() != null) {
                condiciones.add(cb.equal(cb.lower(root.get("zona")), filtro.zona().toLowerCase(Locale.ROOT)));
            }
            if (filtro.colonia() != null) {
                condiciones.add(cb.equal(cb.lower(root.get("colonia")), filtro.colonia().toLowerCase(Locale.ROOT)));
            }
            return cb.and(condiciones.toArray(Predicate[]::new));
        };
    }
}
