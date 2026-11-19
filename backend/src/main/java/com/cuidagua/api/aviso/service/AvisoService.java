package com.cuidagua.api.aviso.service;

import com.cuidagua.api.aviso.dto.AvisoRequest;
import com.cuidagua.api.aviso.dto.AvisoResponse;
import com.cuidagua.api.aviso.entity.Aviso;
import com.cuidagua.api.aviso.repository.AvisoRepository;
import com.cuidagua.api.common.exception.ReglaNegocioException;
import com.cuidagua.api.common.util.TextoUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AvisoService {

    private final AvisoRepository avisoRepository;

    /**
     * Publica un aviso de suministro.
     *
     * @param creadoPorId     claim "sub" del token del administrador
     * @param creadoPorNombre claim "preferred_username" del token
     */
    @Transactional
    public AvisoResponse crear(AvisoRequest request, String creadoPorId, String creadoPorNombre) {
        if (request.fechaInicio() != null && !request.fechaInicio().isBefore(request.fechaRestablecimiento())) {
            throw new ReglaNegocioException("fechaInicio",
                    "La fecha de inicio debe ser anterior a la fecha de restablecimiento");
        }

        Aviso aviso = new Aviso();
        aviso.setTitulo(TextoUtils.limpiar(request.titulo()));
        aviso.setMensaje(TextoUtils.limpiar(request.mensaje()));
        aviso.setColonia(TextoUtils.limpiar(request.colonia()));
        aviso.setTipo(request.tipo());
        aviso.setFechaInicio(request.fechaInicio());
        aviso.setFechaRestablecimiento(request.fechaRestablecimiento());
        aviso.setCreadoPorId(creadoPorId);
        aviso.setCreadoPorNombre(creadoPorNombre);
        return AvisoResponse.desde(avisoRepository.save(aviso));
    }

    /** Lista los avisos del más reciente al más antiguo, opcionalmente filtrados por colonia. */
    @Transactional(readOnly = true)
    public List<AvisoResponse> listar(String colonia) {
        String filtro = TextoUtils.limpiar(colonia);
        List<Aviso> avisos = filtro == null
                ? avisoRepository.findAllByOrderByFechaCreacionDescIdDesc()
                : avisoRepository.findByColoniaIgnoreCaseOrderByFechaCreacionDescIdDesc(filtro);
        return avisos.stream().map(AvisoResponse::desde).toList();
    }
}
