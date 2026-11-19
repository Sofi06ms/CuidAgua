import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'ilustraciones.dart';

// ═══════════════════════════════ ETIQUETAS ═══════════════════════════════

/// Etiqueta de color con icono para el estado de un reporte.
class EstadoChip extends StatelessWidget {
  final EstadoReporte estado;
  final bool compacto;

  const EstadoChip({super.key, required this.estado, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    return Etiqueta(
      color: estado.color,
      icono: estado.icono,
      texto: estado.etiqueta,
      compacto: compacto,
    );
  }
}

/// Etiqueta de color para la prioridad de un reporte.
class PrioridadChip extends StatelessWidget {
  final Prioridad prioridad;

  const PrioridadChip({super.key, required this.prioridad});

  @override
  Widget build(BuildContext context) {
    return Etiqueta(
      color: prioridad.color,
      icono: Icons.flag_rounded,
      texto: prioridad.etiqueta,
      compacto: true,
    );
  }
}

/// Pastilla redondeada de color tenue con icono y texto.
class Etiqueta extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String texto;
  final bool compacto;

  const Etiqueta({
    super.key,
    required this.color,
    required this.icono,
    required this.texto,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final tinta = isDark ? Color.lerp(color, Colors.white, 0.45)! : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 10 : 14,
        vertical: compacto ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.13),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: compacto ? 14 : 17, color: tinta),
          SizedBox(width: compacto ? 4 : 6),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tinta,
                fontSize: compacto ? 12 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla gris con icono, para metadatos (ubicación, fecha…).
class Pastilla extends StatelessWidget {
  final IconData icon;
  final String texto;

  const Pastilla({super.key, required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.esOscuro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C3054) : const Color(0xFFEDF2FA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════ ICONOS ═══════════════════════════════

/// Icono cuadrado redondeado con fondo tenue.
class IconoCaja extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double tamano;

  const IconoCaja({
    super.key,
    required this.icono,
    required this.color,
    this.tamano = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(tamano * 0.32),
      ),
      child: Icon(
        icono,
        size: tamano * 0.52,
        color: isDark ? Color.lerp(color, Colors.white, 0.4) : color,
      ),
    );
  }
}

/// Icono dentro de un círculo con degradado pastel.
class IconoCirculo extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double tamano;

  const IconoCirculo({
    super.key,
    required this.icono,
    required this.color,
    this.tamano = 64,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.35), color.withValues(alpha: 0.2)]
              : [
                  Color.lerp(color, Colors.white, 0.82)!,
                  Color.lerp(color, Colors.white, 0.68)!,
                ],
        ),
      ),
      child: Icon(
        icono,
        size: tamano * 0.5,
        color: isDark ? Color.lerp(color, Colors.white, 0.35) : color,
      ),
    );
  }
}

// ═══════════════════════════════ BANNERS ═══════════════════════════════

/// Banner de bienvenida con paisaje y la gota mascota.
class BannerBienvenida extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? extra;
  final String emoji;

  const BannerBienvenida({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.extra,
    this.emoji = '👋',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final colorTexto = isDark ? Colors.white : AppTheme.tinta;

    return LayoutBuilder(
      builder: (context, c) {
        final compacto = c.maxWidth < 560;
        final altoMascota = compacto ? 100.0 : 160.0;
        return Container(
          constraints: BoxConstraints(minHeight: compacto ? 190 : 210),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compacto ? 26 : 32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E6FE8).withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compacto ? 26 : 32),
            child: Stack(
              children: [
                const Positioned.fill(child: PaisajeFondo()),
                Positioned(
                  right: compacto ? 4 : 28,
                  top: compacto ? 6 : null,
                  bottom: compacto ? null : 6,
                  child: SizedBox(
                    width: altoMascota * 1.45,
                    height: altoMascota * 1.1,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: Salpicaduras()),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GotaMascota(alto: altoMascota),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compacto ? 20 : 40,
                    compacto ? 20 : 34,
                    compacto ? 18 : altoMascota * 1.7,
                    compacto ? 18 : 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // En celular, el texto deja espacio a la mascota
                      // (arriba a la derecha) y la píldora usa todo el ancho.
                      Padding(
                        padding: EdgeInsets.only(
                          right: compacto ? altoMascota * 0.95 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: titulo),
                                  if (emoji.isNotEmpty)
                                    TextSpan(text: ' $emoji'),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: compacto ? 28 : 46,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: colorTexto,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitulo,
                              style: TextStyle(
                                fontSize: compacto ? 15 : 21,
                                fontWeight: FontWeight.w600,
                                color: colorTexto.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (extra != null) ...[
                        SizedBox(height: compacto ? 14 : 18),
                        extra!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Píldora blanca translúcida para usar sobre el banner.
class PildoraBanner extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback? onTap;

  const PildoraBanner({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: color,
                child: Icon(icono, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.tinta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de estadística: círculo con icono, número grande y flecha.
class TarjetaEstadistica extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;
  final String? nota;
  final VoidCallback? onTap;

  const TarjetaEstadistica({
    super.key,
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
    this.nota,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final fondo = isDark
        ? Color.lerp(const Color(0xFF12223F), color, 0.12)!
        : Color.lerp(Colors.white, color, 0.07)!;
    final borde = isDark
        ? color.withValues(alpha: 0.3)
        : Color.lerp(Colors.white, color, 0.25)!;

    return LayoutBuilder(
      builder: (context, c) {
        final compacto = c.maxWidth < 260;
        return Material(
          color: fondo,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borde, width: 1.4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: OndaInferior(
                      color: color.withValues(alpha: isDark ? 0.22 : 0.16),
                      alto: compacto ? 26 : 38,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compacto ? 14 : 22,
                      compacto ? 14 : 18,
                      compacto ? 10 : 18,
                      compacto ? 16 : 20,
                    ),
                    child: Row(
                      children: [
                        IconoCirculo(
                          icono: icono,
                          color: color,
                          tamano: compacto ? 46 : 74,
                        ),
                        SizedBox(width: compacto ? 10 : 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valor,
                                style: TextStyle(
                                  fontSize: compacto ? 28 : 40,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppTheme.tinta,
                                ),
                              ),
                              Text(
                                etiqueta,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compacto ? 13 : 16.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : AppTheme.tinta.withValues(alpha: 0.85),
                                ),
                              ),
                              if (nota != null)
                                Text(
                                  nota!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Color.lerp(color, Colors.white, 0.4)
                                        : color,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onTap != null && !compacto)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(
                                alpha: isDark ? 0.3 : 0.14,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 28,
                              color: isDark
                                  ? Color.lerp(color, Colors.white, 0.4)
                                  : color,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Banner de llamada a la acción en azul intenso con botón blanco.
class BannerAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String boton;
  final IconData iconoBoton;
  final VoidCallback onPressed;

  const BannerAccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.boton,
    required this.onPressed,
    this.iconoBoton = Icons.send_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compacto = c.maxWidth < 600;
        final botonW = FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.azul,
            minimumSize: Size(compacto ? double.infinity : 0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 26),
            shape: const StadiumBorder(),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: Icon(iconoBoton),
          label: Text(boton),
        );

        final textos = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: Colors.white,
                fontSize: compacto ? 18 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: compacto ? 14 : 16,
              ),
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.degradadoAccion,
            borderRadius: BorderRadius.circular(compacto ? 24 : 28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B3D91).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compacto ? 24 : 28),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: OndaInferior(
                    color: Colors.white.withValues(alpha: 0.08),
                    alto: 50,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compacto ? 18 : 24),
                  child: compacto
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(icono, color: Colors.white, size: 40),
                                const SizedBox(width: 14),
                                Expanded(child: textos),
                              ],
                            ),
                            const SizedBox(height: 16),
                            botonW,
                          ],
                        )
                      : Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(icono, color: Colors.white, size: 54),
                            const SizedBox(width: 22),
                            Expanded(child: textos),
                            const SizedBox(width: 16),
                            botonW,
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Título de sección con icono a la izquierda y "Ver todos →" opcional.
class TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? accion;
  final VoidCallback? onAccion;
  final Color? color;

  const TituloSeccion({
    super.key,
    required this.icono,
    required this.titulo,
    this.accion,
    this.onAccion,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icono, color: color ?? scheme.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          if (accion != null)
            TextButton(
              onPressed: onAccion,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(accion!, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Encabezado para pantallas secundarias: icono grande, título y subtítulo
/// sobre una tarjeta suave con onda.
class EncabezadoPagina extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final List<Widget> acciones;

  const EncabezadoPagina({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.color = AppTheme.azul,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    return LayoutBuilder(
      builder: (context, c) {
        final compacto = c.maxWidth < 600;
        final cabecera = Row(
          children: [
            IconoCirculo(
              icono: icono,
              color: color,
              tamano: compacto ? 54 : 66,
            ),
            SizedBox(width: compacto ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: compacto ? 24 : 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : AppTheme.tinta,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: compacto ? 14 : 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF12223F),
                      Color.lerp(const Color(0xFF12223F), color, 0.18)!,
                    ]
                  : [Colors.white, Color.lerp(Colors.white, color, 0.1)!],
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3358) : const Color(0xFFE4ECF7),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: OndaInferior(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    alto: 34,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compacto ? 18 : 24),
                  child: compacto || acciones.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cabecera,
                            if (acciones.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: acciones,
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: cabecera),
                            Wrap(spacing: 8, children: acciones),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Selector de filtros en forma de píldoras deslizables.
class FiltroPildoras<T> extends StatelessWidget {
  final List<(T, String, IconData?)> opciones;
  final T seleccion;
  final ValueChanged<T> onChanged;

  const FiltroPildoras({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (valor, texto, icono) in opciones)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: valor == seleccion
                    ? AppTheme.azul
                    : (isDark ? const Color(0xFF12223F) : Colors.white),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: valor == seleccion
                        ? AppTheme.azul
                        : (isDark
                              ? const Color(0xFF1E3358)
                              : const Color(0xFFDCE6F3)),
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onChanged(valor),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icono != null) ...[
                          Icon(
                            icono,
                            size: 18,
                            color: valor == seleccion
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          texto,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: valor == seleccion
                                ? Colors.white
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════ AVISOS ═══════════════════════════════

/// Tarjeta de aviso de suministro, compartida por ambas interfaces.
class AvisoCard extends StatelessWidget {
  final AvisoSuministro aviso;
  final VoidCallback? onEliminar;

  const AvisoCard({super.key, required this.aviso, this.onEliminar});

  static Color colorDe(TipoAviso tipo) => switch (tipo) {
    TipoAviso.corte => AppTheme.naranja,
    TipoAviso.bajaPresion => AppTheme.ambar,
    TipoAviso.mantenimiento => const Color(0xFF7B5CE0),
    TipoAviso.restablecido => AppTheme.menta,
  };

  static IconData iconoDe(TipoAviso tipo) => switch (tipo) {
    TipoAviso.corte || TipoAviso.bajaPresion => Icons.warning_rounded,
    TipoAviso.mantenimiento => Icons.engineering_rounded,
    TipoAviso.restablecido => Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorDe(aviso.tipo);
    final isDark = context.esOscuro;

    final horario = Etiqueta(
      color: color,
      icono: Icons.calendar_month_rounded,
      texto: aviso.horario,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final compacto = c.maxWidth < 620;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: color),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compacto ? 14 : 22,
                      16,
                      compacto ? 8 : 18,
                      16,
                    ),
                    child: Row(
                      children: [
                        IconoCirculo(
                          icono: iconoDe(aviso.tipo),
                          color: color,
                          tamano: compacto ? 54 : 76,
                        ),
                        SizedBox(width: compacto ? 14 : 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                aviso.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: compacto ? 16 : 18.5,
                                  color: isDark ? Colors.white : AppTheme.tinta,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                aviso.detalle,
                                style: TextStyle(
                                  fontSize: compacto ? 14 : 15.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Pastilla(
                                    icon: Icons.location_on_rounded,
                                    texto: aviso.coloniaAfectada,
                                  ),
                                  if (compacto) horario,
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!compacto) ...[
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: horario,
                          ),
                        ],
                        if (onEliminar != null)
                          IconButton(
                            tooltip: 'Eliminar aviso',
                            onPressed: onEliminar,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════ SEGUIMIENTO ═══════════════════════════════

/// Seguimiento visual del avance de un reporte (4 etapas).
class SeguimientoReporte extends StatelessWidget {
  final EstadoReporte estado;

  const SeguimientoReporte({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actual = estado.index;
    const etapas = EstadoReporte.values;
    final activo = AppTheme.azul;
    final inactivo = context.esOscuro
        ? const Color(0xFF1E3358)
        : const Color(0xFFE2EAF5);

    return Row(
      children: [
        for (var i = 0; i < etapas.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.transparent
                              : (i <= actual ? activo : inactivo),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == actual ? 34 : 28,
                      height: i == actual ? 34 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= actual ? activo : inactivo,
                        boxShadow: i == actual
                            ? [
                                BoxShadow(
                                  color: activo.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        i < actual ? Icons.check_rounded : etapas[i].icono,
                        size: 16,
                        color: i <= actual
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i == etapas.length - 1
                              ? Colors.transparent
                              : (i < actual ? activo : inactivo),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  etapas[i].etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == actual ? FontWeight.w800 : FontWeight.w500,
                    color: i <= actual
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
