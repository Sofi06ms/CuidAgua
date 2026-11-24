package com.cuidagua.api.zona.controller;

import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.SecurityConfig;
import com.cuidagua.api.zona.dto.ZonaResponse;
import com.cuidagua.api.zona.service.ZonaService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ZonaController.class)
@Import({SecurityConfig.class, JsonSecurityHandlers.class})
class ZonaControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ZonaService zonaService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @Test
    void listarZonasEsPublico() throws Exception {
        when(zonaService.listar()).thenReturn(List.of(new ZonaResponse(1, "Zona Norte"), new ZonaResponse(2, "Zona Centro")));

        mockMvc.perform(get("/api/zonas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.datos[0].id").value(1))
                .andExpect(jsonPath("$.datos[1].nombre").value("Zona Centro"));
    }
}
