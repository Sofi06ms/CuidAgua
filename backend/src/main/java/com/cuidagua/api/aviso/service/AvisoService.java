package com.cuidagua.api.aviso.service;

import com.cuidagua.api.aviso.dto.AvisoFiltro;
import com.cuidagua.api.aviso.dto.AvisoRequest;
import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.entity.Aviso;
import com.cuidagua.api.aviso.repository.AvisoRepository;
import com.cuidagua.api.aviso.specification.AvisoSpecifications;
import com.cuidagua.api.common.exception.RecursoNoEncontradoException;
import com.cuidagua.api.common.exception.ReglaNegocioException;
import com.cuidagua.api.common.util.TextoUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AvisoService {

    private static final Sort ORDEN_RECIENTES = Sort.by(Sort.Order.desc("fechaCreacion"), Sort.Order.desc("id"));

    private final AvisoRepository avisoRepository;

    /**
     * Publica un aviso de suministro.
     *
     * @param creadoPorId     claim "sub" del token del administrador
     * @param creadoPorNombre claim "preferred_username" del token
     */
    @Transactional
    public AvisoResponse crear(AvisoRequest request, String creadoPorId, String creadoPorNombre) {
        Aviso aviso = new Aviso();
        aplicarDatos(aviso, request);
        aviso.setCreadoPorId(creadoPorId);
        aviso.setCreadoPorNombre(creadoPorNombre);
        return AvisoResponse.desde(avisoRepository.save(aviso));
    }

    /** Lista los avisos del más reciente al más antiguo aplicando los filtros que vengan informados. */
    @Transactional(readOnly = true)
    public List<AvisoResponse> listar(AvisoFiltro filtro) {
        AvisoFiltro limpio = new AvisoFiltro(TextoUtils.limpiar(filtro.zona()), TextoUtils.limpiar(filtro.colonia()),
                filtro.tipo(), filtro.vigentes());
        return avisoRepository.findAll(AvisoSpecifications.conFiltro(limpio, LocalDateTime.now()), ORDEN_RECIENTES)
                .stream().map(AvisoResponse::desde).toList();
    }

    @Transactional(readOnly = true)
    public AvisoResponse obtener(Long id) {
        return AvisoResponse.desde(buscar(id));
    }

    /** Reemplaza los datos de un aviso (corrección de fechas, texto, etc.). Conserva el autor original. */
    @Transactional
    public AvisoResponse actualizar(Long id, AvisoRequest request) {
        Aviso aviso = buscar(id);
        aplicarDatos(aviso, request);
        aviso.setFechaActualizacion(LocalDateTime.now());
        return AvisoResponse.desde(avisoRepository.save(aviso));
    }

    @Transactional
    public void eliminar(Long id) {
        avisoRepository.delete(buscar(id));
    }

    private void aplicarDatos(Aviso aviso, AvisoRequest request) {
        if (request.fechaInicio() != null && !request.fechaInicio().isBefore(request.fechaRestablecimiento())) {
            throw new ReglaNegocioException("fechaInicio",
                    "La fecha de inicio debe ser anterior a la fecha de restablecimiento");
        }
        aviso.setTitulo(TextoUtils.limpiar(request.titulo()));
        aviso.setMensaje(TextoUtils.limpiar(request.mensaje()));
        aviso.setColonia(TextoUtils.limpiar(request.colonia()));
        aviso.setZona(TextoUtils.limpiar(request.zona()));
        aviso.setTipo(request.tipo());
        aviso.setFechaInicio(request.fechaInicio());
        aviso.setFechaRestablecimiento(request.fechaRestablecimiento());
    }

    private Aviso buscar(Long id) {
        return avisoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe un aviso con id " + id));
    }
}
