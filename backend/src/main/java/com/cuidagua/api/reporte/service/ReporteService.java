package com.cuidagua.api.reporte.service;

import com.cuidagua.api.common.exception.ConflictoException;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.common.exception.ReglaNegocioException;
import com.cuidagua.api.common.util.TextoUtils;
import com.cuidagua.api.reporte.dto.CambioEstadoRequest;
import com.cuidagua.api.reporte.dto.HistorialEstadoResponse;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.dto.ResumenReportesResponse;
import com.cuidagua.api.reporte.entity.CategoriaReporte;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.HistorialEstado;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.reporte.repository.HistorialEstadoRepository;
import com.cuidagua.api.reporte.repository.ReporteRepository;
import com.cuidagua.api.reporte.specification.ReporteSpecifications;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.entity.Usuario;
import com.cuidagua.api.usuario.service.UsuarioService;
import com.cuidagua.api.zona.service.ZonaService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.Year;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReporteService {

    /** Más recientes primero; el id desempata reportes creados en el mismo instante. */
    private static final Sort ORDEN_RECIENTES = Sort.by(Sort.Order.desc("fechaCreacion"), Sort.Order.desc("id"));

    static final String OBSERVACION_REGISTRO = "Reporte registrado";

    private final ReporteRepository reporteRepository;
    private final HistorialEstadoRepository historialRepository;
    private final UsuarioService usuarioService;
    private final ZonaService zonaService;

    /**
     * Registra un reporte en estado pendiente con su folio, sus evidencias y la primera fila del historial.
     *
     * @param autor datos del token del ciudadano
     */
    @Transactional
    public ReporteResponse crear(ReporteRequest request, UsuarioToken autor) {
        if ((request.latitud() == null) != (request.longitud() == null)) {
            String faltante = request.latitud() == null ? "latitud" : "longitud";
            throw new ReglaNegocioException(faltante, "La latitud y la longitud deben enviarse juntas");
        }

        Reporte reporte = new Reporte();
        reporte.setZona(zonaService.buscarParaSolicitud(request.zonaId()));
        reporte.setUsuario(usuarioService.sincronizar(autor));
        reporte.setFolio(generarFolio());
        reporte.setCategoria(request.categoria());
        reporte.setDescripcion(TextoUtils.limpiar(request.descripcion()));
        reporte.setLatitud(request.latitud());
        reporte.setLongitud(request.longitud());
        reporte.setEstado(EstadoReporte.PENDIENTE);
        if (request.evidencias() != null) {
            request.evidencias().stream().map(TextoUtils::limpiar).forEach(reporte::agregarEvidencia);
        }
        reporteRepository.save(reporte);

        registrarHistorial(reporte, null, EstadoReporte.PENDIENTE, OBSERVACION_REGISTRO, reporte.getUsuario());
        return ReporteResponse.desde(reporte);
    }

    /** Lista los reportes del más reciente al más antiguo aplicando los filtros que vengan informados. */
    @Transactional(readOnly = true)
    public List<ReporteResponse> listar(ReporteFiltro filtro) {
        return reporteRepository.findAll(ReporteSpecifications.conFiltro(filtro), ORDEN_RECIENTES)
                .stream().map(ReporteResponse::desde).toList();
    }

    @Transactional(readOnly = true)
    public ReporteResponse obtener(Integer id) {
        return ReporteResponse.desde(buscar(id));
    }

    /** Reportes del usuario del token (claim "sub"), para que el ciudadano dé seguimiento a los suyos. */
    @Transactional(readOnly = true)
    public List<ReporteResponse> listarDeUsuario(String keycloakId) {
        return reporteRepository.findByUsuarioKeycloakIdOrderByFechaCreacionDescIdDesc(keycloakId)
                .stream().map(ReporteResponse::desde).toList();
    }

    /** Cambios de estado de un reporte, del más antiguo al más reciente. */
    @Transactional(readOnly = true)
    public List<HistorialEstadoResponse> historial(Integer id) {
        buscar(id);
        return historialRepository.findByReporteIdOrderByFechaAscIdAsc(id)
                .stream().map(HistorialEstadoResponse::desde).toList();
    }

    /**
     * Cambia el estado de un reporte respetando el flujo de {@link EstadoReporte}
     * y guarda el cambio en historial_estados.
     *
     * @param responsable datos del token de quien hace el cambio (personal o administrador)
     */
    @Transactional
    public ReporteResponse cambiarEstado(Integer id, CambioEstadoRequest request, UsuarioToken responsable) {
        Reporte reporte = buscar(id);
        EstadoReporte actual = reporte.getEstado();
        EstadoReporte nuevo = request.estado();
        String observacion = TextoUtils.limpiar(request.observacion());

        if (actual == nuevo) {
            throw new ConflictoException("estado", "El reporte ya está en estado " + actual);
        }
        if (!actual.puedeCambiarA(nuevo)) {
            String motivo = actual.esFinal()
                    ? "El reporte está en estado " + actual + " y ya no puede cambiar"
                    : "No se puede pasar de " + actual + " a " + nuevo + ". Permitidos: "
                    + actual.siguientesPermitidos().stream().map(EstadoReporte::getValor)
                    .collect(Collectors.joining(", "));
            throw new ConflictoException("estado", motivo);
        }
        if (nuevo == EstadoReporte.RECHAZADO && observacion == null) {
            throw new ReglaNegocioException("observacion", "Indica el motivo del rechazo en la observación");
        }

        reporte.setEstado(nuevo);
        reporte.setFechaActualizacion(LocalDateTime.now());
        reporteRepository.save(reporte);

        registrarHistorial(reporte, actual, nuevo, observacion, usuarioService.sincronizar(responsable));
        return ReporteResponse.desde(reporte);
    }

    /** Conteo de reportes por estado y por categoría para el tablero del panel. */
    @Transactional(readOnly = true)
    public ResumenReportesResponse resumen() {
        Map<String, Long> porEstado = new LinkedHashMap<>();
        for (EstadoReporte estado : EstadoReporte.values()) {
            porEstado.put(estado.getValor(), 0L);
        }
        reporteRepository.contarPorEstado()
                .forEach(fila -> porEstado.put(((EstadoReporte) fila[0]).getValor(), (Long) fila[1]));

        Map<String, Long> porCategoria = new LinkedHashMap<>();
        for (CategoriaReporte categoria : CategoriaReporte.values()) {
            porCategoria.put(categoria.getValor(), 0L);
        }
        reporteRepository.contarPorCategoria()
                .forEach(fila -> porCategoria.put(((CategoriaReporte) fila[0]).getValor(), (Long) fila[1]));

        long total = porEstado.values().stream().mapToLong(Long::longValue).sum();
        return new ResumenReportesResponse(total, porEstado, porCategoria);
    }

    /** CA-&lt;año&gt;-&lt;consecutivo&gt;, ej. CA-2026-000001. El consecutivo es global (no se reinicia cada año). */
    private String generarFolio() {
        return "CA-%d-%06d".formatted(Year.now().getValue(), reporteRepository.siguienteConsecutivoFolio());
    }

    private void registrarHistorial(Reporte reporte, EstadoReporte anterior, EstadoReporte nuevo,
                                    String observacion, Usuario responsable) {
        HistorialEstado historial = new HistorialEstado();
        historial.setReporte(reporte);
        historial.setEstadoAnterior(anterior);
        historial.setEstadoNuevo(nuevo);
        historial.setObservacion(observacion);
        historial.setResponsable(responsable);
        historialRepository.save(historial);
    }

    private Reporte buscar(Integer id) {
        return reporteRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe un reporte con id " + id));
    }
}
