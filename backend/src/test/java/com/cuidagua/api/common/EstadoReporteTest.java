package com.cuidagua.api.common;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Flujo de estados y valores del catálogo. */
class EstadoReporteTest {

    @Test
    void flujoDeEstados() {
        assertThat(EstadoReporte.PENDIENTE.puedeCambiarA(EstadoReporte.EN_REVISION)).isTrue();
        assertThat(EstadoReporte.EN_REVISION.puedeCambiarA(EstadoReporte.RESUELTO)).isTrue();
        assertThat(EstadoReporte.EN_REVISION.puedeCambiarA(EstadoReporte.PENDIENTE)).isFalse();
        assertThat(EstadoReporte.RESUELTO.esFinal()).isTrue();
        assertThat(EstadoReporte.RECHAZADO.esFinal()).isTrue();
    }

    @Test
    void valoresDelCatalogoCoincidenConLaBaseDeDatos() {
        assertThat(EstadoReporte.EN_REVISION.getValor()).isEqualTo("en_revision");
        assertThat(CategoriaReporte.TUBERIA_DANADA.getValor()).isEqualTo("tuberia_danada");
        assertThat(ValorCatalogo.desde(CategoriaReporte.class, "Falta_Suministro"))
                .isEqualTo(CategoriaReporte.FALTA_SUMINISTRO);
        assertThatThrownBy(() -> ValorCatalogo.desde(EstadoReporte.class, "en_proceso"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pendiente, en_revision, resuelto, rechazado");
    }
}
