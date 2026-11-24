package com.cuidagua.api.usuario.repository;

import com.cuidagua.api.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {

    Optional<Usuario> findByKeycloakId(String keycloakId);

    Optional<Usuario> findByCorreo(String correo);
}
