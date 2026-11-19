import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ilustraciones.dart';

/// Un destino de navegación (barra lateral y barra inferior).
class DestinoNav {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final int contador;

  const DestinoNav({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    this.contador = 0,
  });
}

/// Ancho a partir del cual se usa barra lateral en lugar de barra inferior.
const anchoEscritorio = 1000.0;

/// Barra lateral azul marino con logo, menú, ilustración y tarjeta inferior.
class BarraLateral extends StatelessWidget {
  final List<DestinoNav> destinos;
  final int seleccion;
  final ValueChanged<int> onSeleccion;
  final String? etiquetaApp;
  final Widget pie;

  const BarraLateral({
    super.key,
    required this.destinos,
    required this.seleccion,
    required this.onSeleccion,
    required this.pie,
    this.etiquetaApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(gradient: AppTheme.degradadoLateral),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final conIlustracion = c.maxHeight >= 720;
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
              child: Column(
                children: [
                  const LogoCuidAgua(tamano: 30, vertical: true),
                  if (etiquetaApp != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        etiquetaApp!,
                        style: const TextStyle(
                          color: Color(0xFF9FD4FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  for (var i = 0; i < destinos.length; i++)
                    _ItemLateral(
                      destino: destinos[i],
                      seleccionado: seleccion == i,
                      onTap: () => onSeleccion(i),
                    ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withValues(alpha: 0.15)),
                  if (conIlustracion) ...[
                    const Spacer(),
                    const PlanetaEco(tamano: 150),
                    const SizedBox(height: 6),
                    const Text(
                      'Cuidemos\nel agua juntos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const TrazoPincel(),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  pie,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  final DestinoNav destino;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ItemLateral({
    required this.destino,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: seleccionado
              ? const LinearGradient(
                  colors: [Color(0xFF2B7BF2), Color(0xFF1E6FE8)],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E6FE8).withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Icon(
                    seleccionado ? destino.iconoActivo : destino.icono,
                    color: Colors.white.withValues(
                      alpha: seleccionado ? 1 : 0.85,
                    ),
                    size: 27,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      destino.etiqueta,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: seleccionado ? 1 : 0.88,
                        ),
                        fontSize: 16,
                        fontWeight: seleccionado
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (destino.contador > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? Colors.white
                            : const Color(0xFFFF5A5F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${destino.contador}',
                        style: TextStyle(
                          color: seleccionado ? AppTheme.azul : Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con borde al pie de la barra lateral (comunidad / usuario).
class PieLateral extends StatelessWidget {
  final Widget avatar;
  final String titulo;
  final String subtitulo;
  final IconData iconoAccion;
  final String tooltip;
  final VoidCallback onTap;

  const PieLateral({
    super.key,
    required this.avatar,
    required this.titulo,
    required this.subtitulo,
    required this.iconoAccion,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(iconoAccion, color: Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra inferior flotante con indicador en forma de píldora.
class NavInferior extends StatelessWidget {
  final List<DestinoNav> destinos;
  final int seleccion;
  final ValueChanged<int> onSeleccion;

  const NavInferior({
    super.key,
    required this.destinos,
    required this.seleccion,
    required this.onSeleccion,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12223F) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3358)
                      : const Color(0xFFE4ECF7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B2350).withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinos.length; i++)
                    Expanded(
                      child: _ItemInferior(
                        destino: destinos[i],
                        seleccionado: i == seleccion,
                        onTap: () => onSeleccion(i),
                        colorActivo: isDark
                            ? const Color(0xFF8DBAFF)
                            : AppTheme.azul,
                        colorInactivo: scheme.onSurfaceVariant,
                        fondoActivo: isDark
                            ? const Color(0xFF1E3A6B)
                            : const Color(0xFFDCEBFF),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemInferior extends StatelessWidget {
  final DestinoNav destino;
  final bool seleccionado;
  final VoidCallback onTap;
  final Color colorActivo;
  final Color colorInactivo;
  final Color fondoActivo;

  const _ItemInferior({
    required this.destino,
    required this.seleccionado,
    required this.onTap,
    required this.colorActivo,
    required this.colorInactivo,
    required this.fondoActivo,
  });

  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? colorActivo : colorInactivo;
    return Semantics(
      selected: seleccionado,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: seleccionado ? fondoActivo : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: destino.contador > 0,
                label: Text('${destino.contador}'),
                child: Icon(
                  seleccionado ? destino.iconoActivo : destino.icono,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                destino.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado compacto para celular: logo a la izquierda y acciones.
class BarraSuperiorMovil extends StatelessWidget {
  final String? etiqueta;
  final List<Widget> acciones;

  const BarraSuperiorMovil({
    super.key,
    this.etiqueta,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          LogoCuidAgua(tamano: 22, claro: isDark),
          if (etiqueta != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.azul.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  etiqueta!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF8DBAFF) : AppTheme.azul,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          ...acciones,
        ],
      ),
    );
  }
}
