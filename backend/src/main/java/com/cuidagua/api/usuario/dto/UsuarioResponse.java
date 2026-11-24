package com.cuidagua.api.usuario.dto;

import com.cuidagua.api.usuario.entity.RolUsuario;
import com.cuidagua.api.usuario.entity.Usuario;

/**
 * Datos del usuario que devuelve la API (GET /api/usuarios/me).
 *
 * @param id     id de la tabla usuarios
 * @param nombre nombre tomado del token de Keycloak
 * @param correo correo en minúsculas
 * @param rol    ciudadano, personal o administrador
 */
public record UsuarioResponse(Integer id, String nombre, String correo, RolUsuario rol) {

    public static UsuarioResponse desde(Usuario usuario) {
        return new UsuarioResponse(usuario.getId(), usuario.getNombre(), usuario.getCorreo(), usuario.getRol());
    }
}
