package com.cuidagua.api.usuario.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Usuario de CuidAgua (tabla "usuarios"). La autenticación la hace Keycloak:
 * el registro se crea o actualiza automáticamente a partir del token (ver UsuarioService).
 */
@Entity
@Table(name = "usuarios")
@Getter
@Setter
@NoArgsConstructor
public class Usuario {

    /**
     * Valor fijo para la columna credencial_hash (NOT NULL en el diseño oficial).
     * Indica que la contraseña la administra Keycloak; no es un hash ni una contraseña.
     */
    public static final String CREDENCIAL_EXTERNA = "KEYCLOAK";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, length = 100)
    private String nombre;

    /** Siempre en minúsculas. */
    @Column(nullable = false, unique = true, length = 150)
    private String correo;

    @Column(name = "credencial_hash", nullable = false)
    private String credencialHash;

    @Convert(converter = RolUsuarioConverter.class)
    @Column(nullable = false, length = 20)
    private RolUsuario rol;

    @Column(name = "fecha_registro", updatable = false)
    private LocalDateTime fechaRegistro;

    /** Claim "sub" del token de Keycloak (columna agregada en V2). */
    @Column(name = "keycloak_id", unique = true, length = 64)
    private String keycloakId;

    @PrePersist
    void alCrear() {
        if (credencialHash == null) {
            credencialHash = CREDENCIAL_EXTERNA;
        }
        if (fechaRegistro == null) {
            fechaRegistro = LocalDateTime.now();
        }
    }
}
