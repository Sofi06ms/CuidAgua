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
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.service.UsuarioService;
import com.cuidagua.api.zona.service.ZonaService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AvisoService {

    private static final Sort ORDEN_RECIENTES = Sort.by(Sort.Order.desc("fechaPublicacion"), Sort.Order.desc("id"));

    private final AvisoRepository avisoRepository;
    private final UsuarioService usuarioService;
    private final ZonaService zonaService;

    /**
     * Publica un aviso de suministro.
     *
     * @param autor datos del token del administrador
     */
    @Transactional
    public AvisoResponse crear(AvisoRequest request, UsuarioToken autor) {
        Aviso aviso = new Aviso();
        aplicarDatos(aviso, request);
        aviso.setCreadoPor(usuarioService.sincronizar(autor));
        return AvisoResponse.desde(avisoRepository.save(aviso));
    }

    /** Lista los avisos del más reciente al más antiguo aplicando los filtros que vengan informados. */
    @Transactional(readOnly = true)
    public List<AvisoResponse> listar(AvisoFiltro filtro) {
        return avisoRepository.findAll(AvisoSpecifications.conFiltro(filtro, LocalDateTime.now()), ORDEN_RECIENTES)
                .stream().map(AvisoResponse::desde).toList();
    }

    @Transactional(readOnly = true)
    public AvisoResponse obtener(Integer id) {
        return AvisoResponse.desde(buscar(id));
    }

    /** Reemplaza los datos de un aviso (corrección de fechas, texto, etc.). Conserva el autor original. */
    @Transactional
    public AvisoResponse actualizar(Integer id, AvisoRequest request) {
        Aviso aviso = buscar(id);
        aplicarDatos(aviso, request);
        aviso.setFechaActualizacion(LocalDateTime.now());
        return AvisoResponse.desde(avisoRepository.save(aviso));
    }

    @Transactional
    public void eliminar(Integer id) {
        avisoRepository.delete(buscar(id));
    }

    private void aplicarDatos(Aviso aviso, AvisoRequest request) {
        if (request.fechaInicio() != null && !request.fechaInicio().isBefore(request.fechaRestablecimiento())) {
            throw new ReglaNegocioException("fechaInicio",
                    "La fecha de inicio debe ser anterior a la fecha de restablecimiento");
        }
        aviso.setZona(request.zonaId() == null ? null : zonaService.buscarParaSolicitud(request.zonaId()));
        aviso.setTitulo(TextoUtils.limpiar(request.titulo()));
        aviso.setMensaje(TextoUtils.limpiar(request.mensaje()));
        aviso.setTipo(request.tipo());
        aviso.setFechaInicio(request.fechaInicio());
        aviso.setFechaRestablecimiento(request.fechaRestablecimiento());
    }

    private Aviso buscar(Integer id) {
        return avisoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe un aviso con id " + id));
    }
}
