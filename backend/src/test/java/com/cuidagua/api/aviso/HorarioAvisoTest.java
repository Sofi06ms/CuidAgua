package com.cuidagua.api.aviso;

import com.cuidagua.api.aviso.dto.HorarioAviso;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class HorarioAvisoTest {

    private static final int ANIO = 2026;

    @Test
    void conInicioYFin() {
        assertThat(HorarioAviso.describir(
                LocalDateTime.of(2026, 11, 25, 8, 0), LocalDateTime.of(2026, 11, 25, 18, 0), ANIO))
                .isEqualTo("Del 25 nov 08:00 al 25 nov 18:00");
    }

    @Test
    void sinInicio() {
        assertThat(HorarioAviso.describir(null, LocalDateTime.of(2026, 11, 25, 18, 0), ANIO))
                .isEqualTo("Hasta el 25 nov 18:00");
    }

    @Test
    void diaSinCeroYMinutosConCero() {
        assertThat(HorarioAviso.describir(null, LocalDateTime.of(2026, 3, 5, 7, 5), ANIO))
                .isEqualTo("Hasta el 5 mar 07:05");
    }

    @Test
    void muestraElAnioSoloSiNoEsElActual() {
        assertThat(HorarioAviso.describir(
                LocalDateTime.of(2026, 12, 30, 8, 0), LocalDateTime.of(2027, 1, 2, 18, 30), ANIO))
                .isEqualTo("Del 30 dic 08:00 al 2 ene 2027 18:30");
    }

    @Test
    void sinFechaDeRestablecimientoDevuelveNull() {
        assertThat(HorarioAviso.describir(null, null, ANIO)).isNull();
    }
}
