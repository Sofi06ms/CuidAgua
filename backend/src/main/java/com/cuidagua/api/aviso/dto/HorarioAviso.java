package com.cuidagua.api.aviso.dto;

import java.time.LocalDateTime;

/**
 * Arma el texto legible del horario de un aviso a partir de sus fechas. No se guarda en la base de datos.
 * <ul>
 *   <li>Con fecha de inicio: {@code "Del 25 nov 08:00 al 25 nov 18:00"}</li>
 *   <li>Sin fecha de inicio: {@code "Hasta el 25 nov 18:00"}</li>
 * </ul>
 * El año solo se agrega cuando la fecha no es del año actual (ej. {@code "2 ene 2027 18:00"}).
 */
public final class HorarioAviso {

    /** Abreviaturas fijas en español (las de {@code Locale} cambian según la versión de Java, ej. "nov."). */
    private static final String[] MESES = {
            "ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"
    };

    private HorarioAviso() {
    }

    /**
     * @param inicio     fecha de inicio (opcional)
     * @param fin        fecha de restablecimiento
     * @param anioActual año de referencia para decidir si se muestra el año
     * @return el horario en texto, o null si no hay fecha de restablecimiento
     */
    public static String describir(LocalDateTime inicio, LocalDateTime fin, int anioActual) {
        if (fin == null) {
            return null;
        }
        if (inicio == null) {
            return "Hasta el " + fecha(fin, anioActual);
        }
        return "Del " + fecha(inicio, anioActual) + " al " + fecha(fin, anioActual);
    }

    private static String fecha(LocalDateTime f, int anioActual) {
        StringBuilder texto = new StringBuilder()
                .append(f.getDayOfMonth()).append(' ')
                .append(MESES[f.getMonthValue() - 1]);
        if (f.getYear() != anioActual) {
            texto.append(' ').append(f.getYear());
        }
        return texto.append(' ').append(String.format("%02d:%02d", f.getHour(), f.getMinute())).toString();
    }
}
