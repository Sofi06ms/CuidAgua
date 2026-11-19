package com.cuidagua.api.reporte.service;

import com.cuidagua.api.common.util.TextoUtils;
import com.cuidagua.api.reporte.dto.ReporteRequest;
import com.cuidagua.api.reporte.dto.ReporteResponse;
import com.cuidagua.api.reporte.entity.EstadoReporte;
import com.cuidagua.api.reporte.entity.Reporte;
import com.cuidagua.api.reporte.repository.ReporteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ReporteService {

    private final ReporteRepository reporteRepository;

    /**
     * Registra un reporte nuevo en estado PENDIENTE.
     *
     * @param usuarioId     claim "sub" del token
     * @param usuarioNombre claim "preferred_username" del token
     */
    @Transactional
    public ReporteResponse crear(ReporteRequest request, String usuarioId, String usuarioNombre) {
        Reporte reporte = new Reporte();
        reporte.setTipo(request.tipo());
        reporte.setDescripcion(TextoUtils.limpiar(request.descripcion()));
        reporte.setDireccion(TextoUtils.limpiar(request.direccion()));
        reporte.setColonia(TextoUtils.limpiar(request.colonia()));
        reporte.setLatitud(request.latitud());
        reporte.setLongitud(request.longitud());
        reporte.setFotoUrl(TextoUtils.limpiar(request.fotoUrl()));
        reporte.setEstado(EstadoReporte.PENDIENTE);
        reporte.setUsuarioId(usuarioId);
        reporte.setUsuarioNombre(usuarioNombre);
        return ReporteResponse.desde(reporteRepository.save(reporte));
    }

    /** Lista los reportes del más reciente al más antiguo, opcionalmente filtrados por colonia. */
    @Transactional(readOnly = true)
    public List<ReporteResponse> listar(String colonia) {
        String filtro = TextoUtils.limpiar(colonia);
        List<Reporte> reportes = filtro == null
                ? reporteRepository.findAllByOrderByFechaCreacionDescIdDesc()
                : reporteRepository.findByColoniaIgnoreCaseOrderByFechaCreacionDescIdDesc(filtro);
        return reportes.stream().map(ReporteResponse::desde).toList();
    }
}
