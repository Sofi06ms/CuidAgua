package com.cuidagua.api.usuario.service;

import com.cuidagua.api.common.exception.ConflictoException;
import com.cuidagua.api.usuario.dto.UsuarioToken;
import com.cuidagua.api.usuario.entity.Usuario;
import com.cuidagua.api.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Relaciona el usuario del token de Keycloak con la tabla usuarios.
 * Keycloak es la fuente de verdad: nombre, correo y rol se actualizan en cada sincronización.
 */
@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;

    /**
     * Devuelve el usuario del token y lo crea si es su primera petición.
     * <ol>
     *   <li>Busca por keycloak_id (claim "sub").</li>
     *   <li>Si no existe y hay un usuario con el mismo correo sin keycloak_id (dado de alta antes, por ejemplo
     *       desde un script), lo vincula, pero solo si Keycloak marca el correo como verificado.</li>
     *   <li>Si no, crea el usuario con credencial_hash = 'KEYCLOAK'.</li>
     * </ol>
     *
     * @throws ConflictoException si el correo ya pertenece a otro usuario
     */
    @Transactional
    public Usuario sincronizar(UsuarioToken token) {
        Usuario usuario = usuarioRepository.findByKeycloakId(token.keycloakId()).orElse(null);

        Optional<Usuario> conMismoCorreo = usuarioRepository.findByCorreo(token.correo());
        if (conMismoCorreo.isPresent() && conMismoCorreo.get() != usuario) {
            Usuario otro = conMismoCorreo.get();
            boolean vinculable = usuario == null && otro.getKeycloakId() == null && token.correoVerificado();
            if (!vinculable) {
                throw new ConflictoException("correo",
                        "El correo " + token.correo() + " ya está registrado con otra cuenta");
            }
            usuario = otro;
        }

        if (usuario == null) {
            usuario = new Usuario();
            usuario.setCredencialHash(Usuario.CREDENCIAL_EXTERNA);
        }
        usuario.setKeycloakId(token.keycloakId());
        usuario.setNombre(token.nombre());
        usuario.setCorreo(token.correo());
        usuario.setRol(token.rol());
        return usuarioRepository.save(usuario);
    }
}
