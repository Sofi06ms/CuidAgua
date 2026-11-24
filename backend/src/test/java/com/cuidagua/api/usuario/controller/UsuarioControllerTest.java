package com.cuidagua.api.usuario.controller;

import com.cuidagua.api.config.JsonSecurityHandlers;
import com.cuidagua.api.config.SecurityConfig;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.entity.RolUsuario;
import com.cuidagua.api.usuario.entity.Usuario;
import com.cuidagua.api.usuario.service.UsuarioService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static com.cuidagua.api.TokensPrueba.token;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UsuarioController.class)
@Import({SecurityConfig.class, JsonSecurityHandlers.class})
class UsuarioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UsuarioService usuarioService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @Test
    void meSinTokenDevuelve401() throws Exception {
        mockMvc.perform(get("/api/usuarios/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.exito").value(false));

        verifyNoInteractions(usuarioService);
    }

    @Test
    void meDevuelveLosDatosDelUsuarioDelToken() throws Exception {
        Usuario usuario = new Usuario();
        usuario.setId(7);
        usuario.setNombre("Nombre admin1");
        usuario.setCorreo("admin1@cuidagua.local");
        usuario.setRol(RolUsuario.ADMINISTRADOR);
        when(usuarioService.sincronizar(any(UsuarioToken.class))).thenReturn(usuario);

        mockMvc.perform(get("/api/usuarios/me").with(token("admin1", "ADMIN", "CIUDADANO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.exito").value(true))
                .andExpect(jsonPath("$.datos.id").value(7))
                .andExpect(jsonPath("$.datos.nombre").value("Nombre admin1"))
                .andExpect(jsonPath("$.datos.correo").value("admin1@cuidagua.local"))
                .andExpect(jsonPath("$.datos.rol").value("administrador"));
    }
}
