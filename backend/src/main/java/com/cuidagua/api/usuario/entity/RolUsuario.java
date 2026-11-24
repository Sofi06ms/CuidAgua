package com.cuidagua.api.usuario.entity;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * Rol del usuario en la tabla usuarios. Se calcula a partir de los roles de Keycloak:
 * ADMIN -> administrador, PERSONAL -> personal, cualquier otro -> ciudadano.
 */
public enum RolUsuario implements ValorCatalogo {
    CIUDADANO("ciudadano"),
    PERSONAL("personal"),
    ADMINISTRADOR("administrador");

    private final String valor;

    RolUsuario(String valor) {
        this.valor = valor;
    }

    @Override
    @JsonValue
    public String getValor() {
        return valor;
    }

    @Override
    public String toString() {
        return valor;
    }
}
