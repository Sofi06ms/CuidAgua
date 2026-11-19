import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Ilustraciones de CuidAgua dibujadas con CustomPainter: no requieren
// archivos de imagen y se adaptan a cualquier tamaño y al modo oscuro.

/// Forma de gota: punta arriba y base redonda, ocupando [r].
Path _gota(Rect r) {
  final cx = r.center.dx;
  final radio = r.width / 2;
  final cy = r.bottom - radio;
  return Path()
    ..moveTo(cx, r.top)
    ..cubicTo(
      cx + radio * 0.35,
      r.top + r.height * 0.22,
      cx + radio,
      cy - radio * 0.55,
      cx + radio,
      cy,
    )
    ..arcToPoint(
      Offset(cx - radio, cy),
      radius: Radius.circular(radio),
      clockwise: true,
    )
    ..cubicTo(
      cx - radio,
      cy - radio * 0.55,
      cx - radio * 0.35,
      r.top + r.height * 0.22,
      cx,
      r.top,
    )
    ..close();
}

/// Hoja con nervadura, apuntando hacia [angulo] (radianes).
void _hoja(
  Canvas canvas,
  Offset base,
  double largo,
  double angulo,
  Color color, {
  Color? nervadura,
}) {
  canvas.save();
  canvas.translate(base.dx, base.dy);
  canvas.rotate(angulo);
  final ancho = largo * 0.42;
  final path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(ancho, -largo * 0.45, 0, -largo)
    ..quadraticBezierTo(-ancho, -largo * 0.45, 0, 0)
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, Color.lerp(color, Colors.white, 0.25)!],
      ).createShader(Rect.fromLTWH(-ancho, -largo, ancho * 2, largo)),
  );
  canvas.drawLine(
    Offset.zero,
    Offset(0, -largo * 0.85),
    Paint()
      ..color = nervadura ?? Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = math.max(1, largo * 0.04)
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}

// ═══════════════════════════════ LOGO ═══════════════════════════════

/// Logo de CuidAgua: gota azul con una hoja verde.
class LogoGota extends StatelessWidget {
  final double tamano;

  const LogoGota({super.key, this.tamano = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rect = Rect.fromLTWH(w * 0.14, 0, w * 0.72, w * 0.98);
    final gota = _gota(rect);

    canvas.drawPath(
      gota.shift(Offset(0, w * 0.03)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
    canvas.drawPath(
      gota,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7FD8FF), Color(0xFF2A8CF0), Color(0xFF1456C8)],
        ).createShader(rect),
    );
    // Interior claro
    final interior = _gota(rect.deflate(w * 0.1).translate(0, w * 0.04));
    canvas.drawPath(
      interior,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    // Hojas
    final base = Offset(w * 0.5, w * 0.8);
    _hoja(canvas, base, w * 0.42, -0.75, const Color(0xFF27A65A));
    _hoja(canvas, base, w * 0.48, 0.55, const Color(0xFF3CC46E));
    // Brillo
    canvas.drawOval(
      Rect.fromLTWH(w * 0.3, w * 0.3, w * 0.1, w * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Logo con texto "CuidAgua" (Cuid blanco/tinta, Agua azul claro).
class LogoCuidAgua extends StatelessWidget {
  final double tamano;
  final bool claro;
  final bool vertical;

  const LogoCuidAgua({
    super.key,
    this.tamano = 28,
    this.claro = true,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Cuid',
            style: TextStyle(color: claro ? Colors.white : AppTheme.tinta),
          ),
          TextSpan(
            text: 'Agua',
            style: TextStyle(
              color: claro ? const Color(0xFF6FC8FF) : AppTheme.azul,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.1,
      ),
    );
    final logo = LogoGota(tamano: vertical ? tamano * 2.6 : tamano * 1.5);
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          SizedBox(height: tamano * 0.25),
          texto,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        SizedBox(width: tamano * 0.3),
        texto,
      ],
    );
  }
}

// ═══════════════════════════════ MASCOTA ═══════════════════════════════

/// Gota sonriente, mascota de CuidAgua. Flota suavemente.
class GotaMascota extends StatefulWidget {
  final double alto;
  final bool pulgarArriba;
  final bool animada;

  const GotaMascota({
    super.key,
    this.alto = 140,
    this.pulgarArriba = true,
    this.animada = true,
  });

  @override
  State<GotaMascota> createState() => _GotaMascotaState();
}

class _GotaMascotaState extends State<GotaMascota>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animada) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alto = widget.alto;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            -alto * 0.04 * Curves.easeInOut.transform(_c.value),
          ),
          child: child,
        ),
        child: SizedBox(
          width: alto * 1.05,
          height: alto,
          child: CustomPaint(
            painter: _MascotaPainter(pulgar: widget.pulgarArriba),
          ),
        ),
      ),
    );
  }
}

class _MascotaPainter extends CustomPainter {
  final bool pulgar;

  _MascotaPainter({required this.pulgar});

  static const _ojo = Color(0xFF0B1F44);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final ancho = h * 0.78;
    final rect = Rect.fromLTWH(w - ancho - w * 0.02, 0, ancho, h * 0.97);
    final r = ancho / 2;
    final cx = rect.center.dx;
    final cy = rect.bottom - r;

    // Sombra en el piso
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, rect.bottom),
        width: ancho * 0.8,
        height: h * 0.05,
      ),
      Paint()
        ..color = const Color(0xFF0B3D91).withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.015),
    );

    // Cuerpo
    final cuerpo = _gota(rect);
    canvas.drawPath(
      cuerpo,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.2),
          radius: 0.95,
          colors: [Color(0xFF8EDBFF), Color(0xFF3B9BF5), Color(0xFF1659D6)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // Borde interior más oscuro
    canvas.drawPath(
      cuerpo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.012
        ..color = const Color(0xFF0E4FC4).withValues(alpha: 0.35),
    );

    // Brillos
    canvas.save();
    canvas.translate(cx - r * 0.5, cy - r * 0.55);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.22, height: r * 0.55),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(cx - r * 0.25, rect.top + h * 0.22),
      r * 0.06,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Ojos
    for (final s in [-1.0, 1.0]) {
      final centro = Offset(cx + s * r * 0.34, cy - r * 0.12);
      canvas.drawOval(
        Rect.fromCenter(center: centro, width: r * 0.26, height: r * 0.36),
        Paint()..color = _ojo,
      );
      canvas.drawCircle(
        centro + Offset(-r * 0.04, -r * 0.08),
        r * 0.065,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        centro + Offset(r * 0.05, r * 0.06),
        r * 0.03,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
      // Mejillas
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + s * r * 0.6, cy + r * 0.14),
          width: r * 0.24,
          height: r * 0.14,
        ),
        Paint()..color = const Color(0xFFFF7FA8).withValues(alpha: 0.75),
      );
    }

    // Boca abierta con lengua
    final boca = Path()
      ..moveTo(cx - r * 0.24, cy + r * 0.1)
      ..quadraticBezierTo(cx, cy + r * 0.16, cx + r * 0.24, cy + r * 0.1)
      ..quadraticBezierTo(cx + r * 0.2, cy + r * 0.48, cx, cy + r * 0.5)
      ..quadraticBezierTo(
        cx - r * 0.2,
        cy + r * 0.48,
        cx - r * 0.24,
        cy + r * 0.1,
      )
      ..close();
    canvas.drawPath(boca, Paint()..color = const Color(0xFF7A1630));
    canvas.save();
    canvas.clipPath(boca);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.5),
        width: r * 0.34,
        height: r * 0.26,
      ),
      Paint()..color = const Color(0xFFFF6F8E),
    );
    canvas.restore();

    // Mano con pulgar arriba
    if (pulgar) {
      final mano = Offset(cx - r * 1.02, cy + r * 0.05);
      final pintura = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6CC6FF), Color(0xFF1E6FE8)],
        ).createShader(Rect.fromCircle(center: mano, radius: r * 0.4));
      // Brazo
      canvas.drawLine(
        mano + Offset(r * 0.12, r * 0.18),
        Offset(cx - r * 0.8, cy + r * 0.45),
        Paint()
          ..color = const Color(0xFF2B82EE)
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round,
      );
      // Puño
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: mano, width: r * 0.42, height: r * 0.38),
          Radius.circular(r * 0.14),
        ),
        pintura,
      );
      // Pulgar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            mano.dx - r * 0.12,
            mano.dy - r * 0.44,
            r * 0.15,
            r * 0.32,
          ),
          Radius.circular(r * 0.08),
        ),
        pintura,
      );
      // Dedos
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          mano + Offset(-r * 0.04, -r * 0.06 + i * r * 0.1),
          mano + Offset(r * 0.14, -r * 0.06 + i * r * 0.1),
          Paint()
            ..color = const Color(0xFF0E4FC4).withValues(alpha: 0.4)
            ..strokeWidth = r * 0.025
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Hoja junto a la base
    _hoja(
      canvas,
      Offset(cx + r * 0.95, rect.bottom),
      r * 0.75,
      0.35,
      const Color(0xFF2EAD5E),
    );
    _hoja(
      canvas,
      Offset(cx + r * 0.9, rect.bottom),
      r * 0.55,
      1.0,
      const Color(0xFF4CCB78),
    );
  }

  @override
  bool shouldRepaint(_MascotaPainter old) => old.pulgar != pulgar;
}

// ═══════════════════════════════ PAISAJE ═══════════════════════════════

/// Fondo de paisaje (cielo, nubes, montañas, árboles) para el banner.
class PaisajeFondo extends StatelessWidget {
  /// Si es falso, solo dibuja nubes, montañas y agua sobre fondo
  /// transparente (para combinarlo con [CieloFondo] en áreas altas).
  final bool conCielo;

  const PaisajeFondo({super.key, this.conCielo = true});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaisajePainter(oscuro: context.esOscuro, conCielo: conCielo),
    );
  }
}

/// Degradado de cielo a juego con [PaisajeFondo].
class CieloFondo extends StatelessWidget {
  const CieloFondo({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.esOscuro
              ? const [Color(0xFF0F2D5C), Color(0xFF14406F)]
              : const [Color(0xFFB9E3FF), Color(0xFFE6F5FF)],
        ),
      ),
    );
  }
}

class _PaisajePainter extends CustomPainter {
  final bool oscuro;
  final bool conCielo;

  _PaisajePainter({required this.oscuro, this.conCielo = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Offset.zero & size;

    if (conCielo) _cielo(canvas, size);
    _paisaje(canvas, size, w, h, todo);
  }

  void _cielo(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Offset.zero & size;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: oscuro
              ? const [Color(0xFF123B73), Color(0xFF0F2D5C), Color(0xFF14406F)]
              : const [Color(0xFFB9E3FF), Color(0xFFDDF2FF), Color(0xFFC9EBFF)],
        ).createShader(todo),
    );
    // Resplandor
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.1),
      h * 0.9,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: oscuro ? 0.10 : 0.75),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(w * 0.78, h * 0.1),
                radius: h * 0.9,
              ),
            ),
    );
  }

  void _paisaje(Canvas canvas, Size size, double w, double h, Rect todo) {
    // Nubes
    final nube = Paint()
      ..color = Colors.white.withValues(alpha: oscuro ? 0.12 : 0.95);
    void dibujarNube(double x, double y, double s) {
      canvas.drawCircle(Offset(x, y), s * 0.5, nube);
      canvas.drawCircle(Offset(x + s * 0.5, y - s * 0.22), s * 0.62, nube);
      canvas.drawCircle(Offset(x + s * 1.1, y), s * 0.48, nube);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - s * 0.2, y - s * 0.05, s * 1.6, s * 0.5),
          Radius.circular(s * 0.25),
        ),
        nube,
      );
    }

    dibujarNube(w * 0.6, h * 0.36, h * 0.15);
    dibujarNube(w * 0.86, h * 0.18, h * 0.11);
    dibujarNube(w * 0.38, h * 0.16, h * 0.07);

    // Montañas lejanas
    final lejanas = Path()..moveTo(0, h * 0.8);
    final picos = [
      (0.08, 0.62),
      (0.18, 0.7),
      (0.3, 0.52),
      (0.42, 0.68),
      (0.55, 0.5),
      (0.66, 0.66),
      (0.78, 0.55),
      (0.9, 0.68),
      (1.0, 0.6),
    ];
    for (final (x, y) in picos) {
      lejanas.lineTo(w * x, h * y);
    }
    lejanas
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      lejanas,
      Paint()
        ..color = oscuro
            ? const Color(0xFF1C4F86).withValues(alpha: 0.7)
            : const Color(0xFF9FD0F2).withValues(alpha: 0.75),
    );

    // Colinas medias
    final colinas = Path()..moveTo(0, h * 0.86);
    colinas.cubicTo(w * 0.2, h * 0.7, w * 0.35, h * 0.92, w * 0.55, h * 0.8);
    colinas.cubicTo(w * 0.72, h * 0.7, w * 0.85, h * 0.84, w, h * 0.74);
    colinas
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      colinas,
      Paint()
        ..color = oscuro ? const Color(0xFF1B6A6E) : const Color(0xFF8ED8C8),
    );

    // Pinos
    final pino = Paint()
      ..color = oscuro ? const Color(0xFF17575A) : const Color(0xFF4DB39C);
    final pinoClaro = Paint()
      ..color = oscuro ? const Color(0xFF1F6E70) : const Color(0xFF6CC7AE);
    void arbol(double x, double base, double alto, Paint p) {
      final t = Path()
        ..moveTo(x, base - alto)
        ..lineTo(x + alto * 0.32, base)
        ..lineTo(x - alto * 0.32, base)
        ..close();
      canvas.drawPath(t, p);
    }

    for (final (x, a, claro) in [
      (0.5, 0.2, false),
      (0.535, 0.14, true),
      (0.62, 0.17, false),
      (0.66, 0.24, true),
      (0.71, 0.15, false),
      (0.8, 0.2, true),
      (0.06, 0.16, true),
      (0.1, 0.22, false),
      (0.15, 0.14, true),
    ]) {
      arbol(w * x, h * 0.86, h * a, claro ? pinoClaro : pino);
    }

    // Agua al frente
    final agua = Path()..moveTo(0, h * 0.9);
    agua.cubicTo(w * 0.25, h * 0.82, w * 0.45, h * 0.98, w * 0.7, h * 0.9);
    agua.cubicTo(w * 0.85, h * 0.85, w * 0.95, h * 0.92, w, h * 0.88);
    agua
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      agua,
      Paint()
        ..shader = LinearGradient(
          colors: oscuro
              ? const [Color(0xFF1B5FA8), Color(0xFF15808F)]
              : const [Color(0xFF7CC8F0), Color(0xFF6FD3C3)],
        ).createShader(todo),
    );
  }

  @override
  bool shouldRepaint(_PaisajePainter old) =>
      old.oscuro != oscuro || old.conCielo != conCielo;
}

/// Gotitas decorativas que salpican alrededor de la mascota.
class Salpicaduras extends StatelessWidget {
  final Color color;

  const Salpicaduras({super.key, this.color = const Color(0xFF3B9BF5)});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _SalpicadurasPainter(color)),
    );
  }
}

class _SalpicadurasPainter extends CustomPainter {
  final Color color;

  _SalpicadurasPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = LinearGradient(
        colors: [Color.lerp(color, Colors.white, 0.45)!, color],
      ).createShader(Offset.zero & size);
    for (final (x, y, s) in [
      (0.12, 0.18, 0.1),
      (0.9, 0.12, 0.08),
      (0.95, 0.42, 0.06),
      (0.05, 0.5, 0.05),
    ]) {
      final lado = size.height * s;
      canvas.drawPath(
        _gota(
          Rect.fromLTWH(size.width * x, size.height * y, lado * 0.75, lado),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SalpicadurasPainter old) => old.color != color;
}

// ═══════════════════════════════ PLANETA ═══════════════════════════════

/// Planeta con hojas y gota: "Cuidemos el agua juntos".
class PlanetaEco extends StatelessWidget {
  final double tamano;

  const PlanetaEco({super.key, this.tamano = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _PlanetaPainter()),
    );
  }
}

class _PlanetaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * 0.5);
    final r = s * 0.32;

    // Hojas alrededor
    for (final (dx, dy, ang, largo) in [
      (-0.36, 0.12, -1.1, 0.26),
      (-0.3, -0.18, -0.55, 0.22),
      (0.36, 0.12, 1.1, 0.26),
      (0.3, -0.18, 0.55, 0.22),
    ]) {
      _hoja(
        canvas,
        c + Offset(s * dx, s * dy),
        s * largo,
        ang,
        const Color(0xFF3CC46E),
      );
    }

    // Halo
    canvas.drawCircle(
      c,
      r * 1.12,
      Paint()..color = const Color(0xFF38B6FF).withValues(alpha: 0.18),
    );
    // Océano
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFF7FD3FF), Color(0xFF2A86E8), Color(0xFF134FB5)],
        ).createShader(rect),
    );
    // Continentes
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final tierra = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5FD27E), Color(0xFF2E9E57)],
      ).createShader(rect);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.7, c.dy - r * 0.55)
        ..cubicTo(
          c.dx - r * 0.2,
          c.dy - r * 0.95,
          c.dx + r * 0.1,
          c.dy - r * 0.5,
          c.dx - r * 0.15,
          c.dy - r * 0.15,
        )
        ..cubicTo(
          c.dx - r * 0.35,
          c.dy + r * 0.1,
          c.dx - r * 0.1,
          c.dy + r * 0.55,
          c.dx - r * 0.35,
          c.dy + r * 0.8,
        )
        ..cubicTo(
          c.dx - r * 0.75,
          c.dy + r * 0.5,
          c.dx - r * 1.1,
          c.dy - r * 0.1,
          c.dx - r * 0.7,
          c.dy - r * 0.55,
        )
        ..close(),
      tierra,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + r * 0.25, c.dy - r * 0.75)
        ..cubicTo(
          c.dx + r * 0.8,
          c.dy - r * 0.7,
          c.dx + r * 1.0,
          c.dy - r * 0.2,
          c.dx + r * 0.6,
          c.dy + r * 0.05,
        )
        ..cubicTo(
          c.dx + r * 0.4,
          c.dy + r * 0.2,
          c.dx + r * 0.65,
          c.dy + r * 0.55,
          c.dx + r * 0.3,
          c.dy + r * 0.6,
        )
        ..cubicTo(
          c.dx + r * 0.05,
          c.dy + r * 0.2,
          c.dx + r * 0.25,
          c.dy - r * 0.3,
          c.dx + r * 0.25,
          c.dy - r * 0.75,
        )
        ..close(),
      tierra,
    );
    canvas.restore();
    // Brillo
    canvas.drawCircle(
      c + Offset(-r * 0.45, -r * 0.45),
      r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Gota al frente
    final gotaRect = Rect.fromLTWH(
      c.dx + r * 0.35,
      c.dy + r * 0.3,
      r * 0.6,
      r * 0.82,
    );
    canvas.drawPath(
      _gota(gotaRect),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9BE3FF), Color(0xFF2A8CF0)],
        ).createShader(gotaRect),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        gotaRect.left + gotaRect.width * 0.25,
        gotaRect.top + gotaRect.height * 0.45,
        gotaRect.width * 0.14,
        gotaRect.height * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Trazo curvo tipo pincel, para subrayar frases.
class TrazoPincel extends StatelessWidget {
  final double ancho;
  final Color color;

  const TrazoPincel({super.key, this.ancho = 140, this.color = AppTheme.aqua});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: 14,
      child: CustomPaint(painter: _TrazoPainter(color)),
    );
  }
}

class _TrazoPainter extends CustomPainter {
  final Color color;

  _TrazoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.03, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width * 0.97,
        size.height * 0.45,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.35
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrazoPainter old) => old.color != color;
}

/// Onda suave en la parte inferior de una tarjeta.
class OndaInferior extends StatelessWidget {
  final Color color;
  final double alto;

  const OndaInferior({super.key, required this.color, this.alto = 40});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: alto,
        width: double.infinity,
        child: CustomPaint(painter: _OndaPainter(color)),
      ),
    );
  }
}

class _OndaPainter extends CustomPainter {
  final Color color;

  _OndaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final atras = Path()
      ..moveTo(0, h * 0.7)
      ..cubicTo(w * 0.3, h * 0.2, w * 0.6, h * 1.1, w, h * 0.15)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(atras, Paint()..color = color.withValues(alpha: 0.45));
    final frente = Path()
      ..moveTo(w * 0.35, h)
      ..cubicTo(w * 0.55, h * 0.45, w * 0.8, h * 0.75, w, h * 0.4)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(frente, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OndaPainter old) => old.color != color;
}
