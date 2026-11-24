package com.cuidagua.api.zona.service;

import com.cuidagua.api.common.exception.ReglaNegocioException;
import com.cuidagua.api.zona.dto.ZonaResponse;
import com.cuidagua.api.zona.entity.Zona;
import com.cuidagua.api.zona.repository.ZonaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ZonaService {

    private final ZonaRepository zonaRepository;

    @Transactional(readOnly = true)
    public List<ZonaResponse> listar() {
        return zonaRepository.findAll(Sort.by("id")).stream().map(ZonaResponse::desde).toList();
    }

    /**
     * Zona indicada en una solicitud. Un id inexistente es un dato inválido del cliente (400), no un 404.
     */
    @Transactional(readOnly = true)
    public Zona buscarParaSolicitud(Integer id) {
        return zonaRepository.findById(id)
                .orElseThrow(() -> new ReglaNegocioException("zonaId", "No existe una zona con id " + id));
    }
}
