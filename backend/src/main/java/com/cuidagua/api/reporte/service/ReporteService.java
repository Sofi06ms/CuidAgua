package com.cuidagua.api.reporte.service;

import com.cuidagua.api.common.exception.ConflictoException;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.common.exception.ReglaNegocioException;
import com.cuidagua.api.common.util.TextoUtils;
import com.cuidagua.api.reporte.dto.CambioEstadoRequest;
import com.cuidagua.api.reporte.dto.ReporteFiltro;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.dto.ResumenReportesResponse;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.reporte.entity.TipoReporte;
import com.cuidagua.api.reporte.repository.ReporteRepository;
import com.cuidagua.api.reporte.specification.ReporteSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReporteService {

    /** Más recientes primero; el id desempata reportes creados en el mismo instante. */
    private static final Sort ORDEN_RECIENTES = Sort.by(Sort.Order.desc("fechaCreacion"), Sort.Order.desc("id"));

    private final ReporteRepository reporteRepository;

    /**
     * Registra un reporte nuevo en estado PENDIENTE.
     *
     * @param usuarioId     claim "sub" del token
     * @param usuarioNombre claim "preferred_username" del token
     */
    @Transactional
    public ReporteResponse crear(ReporteRequest request, String usuarioId, String usuarioNombre) {
        if ((request.latitud() == null) != (request.longitud() == null)) {
            String faltante = request.latitud() == null ? "latitud" : "longitud";
            throw new ReglaNegocioException(faltante, "La latitud y la longitud deben enviarse juntas");
        }

        Reporte reporte = new Reporte();
        reporte.setTipo(request.tipo());
        reporte.setDescripcion(TextoUtils.limpiar(request.descripcion()));
        reporte.setDireccion(TextoUtils.limpiar(request.direccion()));
        reporte.setColonia(TextoUtils.limpiar(request.colonia()));
        reporte.setZona(TextoUtils.limpiar(request.zona()));
        reporte.setLatitud(request.latitud());
        reporte.setLongitud(request.longitud());
        reporte.setFotoUrl(TextoUtils.limpiar(request.fotoUrl()));
        reporte.setEstado(EstadoReporte.PENDIENTE);
        reporte.setUsuarioId(usuarioId);
        reporte.setUsuarioNombre(usuarioNombre);
        return ReporteResponse.desde(reporteRepository.save(reporte));
    }

    /** Lista los reportes del más reciente al más antiguo aplicando los filtros que vengan informados. */
    @Transactional(readOnly = true)
    public List<ReporteResponse> listar(ReporteFiltro filtro) {
        ReporteFiltro limpio = new ReporteFiltro(filtro.estado(), filtro.tipo(),
                TextoUtils.limpiar(filtro.zona()), TextoUtils.limpiar(filtro.colonia()));
        return reporteRepository.findAll(ReporteSpecifications.conFiltro(limpio), ORDEN_RECIENTES)
                .stream().map(ReporteResponse::desde).toList();
    }

    @Transactional(readOnly = true)
    public ReporteResponse obtener(Long id) {
        return ReporteResponse.desde(buscar(id));
    }

    /** Reportes creados por el usuario del token, para que el ciudadano dé seguimiento a los suyos. */
    @Transactional(readOnly = true)
    public List<ReporteResponse> listarDeUsuario(String usuarioId) {
        return reporteRepository.findByUsuarioIdOrderByFechaCreacionDescIdDesc(usuarioId)
                .stream().map(ReporteResponse::desde).toList();
    }

    /**
     * Cambia el estado de un reporte respetando el flujo definido en {@link EstadoReporte}.
     *
     * @param administrador preferred_username de quien hace el cambio
     */
    @Transactional
    public ReporteResponse cambiarEstado(Long id, CambioEstadoRequest request, String administrador) {
        Reporte reporte = buscar(id);
        EstadoReporte actual = reporte.getEstado();
        EstadoReporte nuevo = request.estado();
        String comentario = TextoUtils.limpiar(request.comentario());

        if (actual == nuevo) {
            throw new ConflictoException("estado", "El reporte ya está en estado " + actual);
        }
        if (!actual.puedeCambiarA(nuevo)) {
            String motivo = actual.esFinal()
                    ? "El reporte está en estado " + actual + " y ya no puede cambiar"
                    : "No se puede pasar de " + actual + " a " + nuevo + ". Permitidos: "
                    + actual.siguientesPermitidos().stream().map(Enum::name).collect(Collectors.joining(", "));
            throw new ConflictoException("estado", motivo);
        }
        if (nuevo == EstadoReporte.RECHAZADO && comentario == null) {
            throw new ReglaNegocioException("comentario", "Indica el motivo del rechazo en el comentario");
        }

        reporte.setEstado(nuevo);
        reporte.setComentarioEstado(comentario);
        reporte.setActualizadoPor(administrador);
        reporte.setFechaActualizacion(LocalDateTime.now());
        return ReporteResponse.desde(reporteRepository.save(reporte));
    }

    /** Conteo de reportes por estado y por tipo para el tablero del panel administrativo. */
    @Transactional(readOnly = true)
    public ResumenReportesResponse resumen() {
        Map<EstadoReporte, Long> porEstado = new EnumMap<>(EstadoReporte.class);
        for (EstadoReporte estado : EstadoReporte.values()) {
            porEstado.put(estado, 0L);
        }
        reporteRepository.contarPorEstado().forEach(fila -> porEstado.put((EstadoReporte) fila[0], (Long) fila[1]));

        Map<TipoReporte, Long> porTipo = new EnumMap<>(TipoReporte.class);
        for (TipoReporte tipo : TipoReporte.values()) {
            porTipo.put(tipo, 0L);
        }
        reporteRepository.contarPorTipo().forEach(fila -> porTipo.put((TipoReporte) fila[0], (Long) fila[1]));

        long total = porEstado.values().stream().mapToLong(Long::longValue).sum();
        return new ResumenReportesResponse(total, porEstado, porTipo);
    }

    private Reporte buscar(Long id) {
        return reporteRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe un reporte con id " + id));
    }
}
