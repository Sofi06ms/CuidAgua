import 'package:flutter/material.dart';

/// Paleta y tema visual de CuidAgua (Material 3, claro y oscuro).
class AppTheme {
  AppTheme._();

  // ── Paleta de marca ──
  static const Color seed = Color(0xFF1E6FE8);
  static const Color azul = Color(0xFF1E6FE8);
  static const Color aqua = Color(0xFF38B6FF);
  static const Color marino = Color(0xFF0B2350);
  static const Color marinoProfundo = Color(0xFF071A3D);
  static const Color tinta = Color(0xFF0B1F44);
  static const Color menta = Color(0xFF2BB673);
  static const Color naranja = Color(0xFFFF7A3D);
  static const Color ambar = Color(0xFFF5A623);

  /// Degradado del banner de acción ("¿Viste una fuga?").
  static const degradadoAccion = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0B3D91), Color(0xFF1257C2), Color(0xFF1E88E5)],
  );

  /// Degradado de la barra lateral.
  static const degradadoLateral = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D2A5E), marino, marinoProfundo],
  );

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: isDark ? const Color(0xFF8DBAFF) : azul,
    );

    final texto =
        (isDark ? Typography.whiteMountainView : Typography.blackMountainView)
            .apply(
              bodyColor: isDark ? Colors.white : tinta,
              displayColor: isDark ? Colors.white : tinta,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: texto.copyWith(
        headlineLarge: texto.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        headlineMedium: texto.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
        titleLarge: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0A1630)
          : const Color(0xFFF2F6FC),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF12223F) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E3358) : const Color(0xFFE4ECF7),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF12223F) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF12223F) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2C4E) : const Color(0xFFF1F5FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

extension TemaContexto on BuildContext {
  bool get esOscuro => Theme.of(this).brightness == Brightness.dark;
}
