import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidagua_app/main.dart';

// La mascota del encabezado se anima sin fin, así que se avanza el reloj
// con pump(duración) en lugar de pumpAndSettle().
Future<void> avanzar(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tamano(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> entrar(WidgetTester tester, {required bool admin}) async {
  await tester.pumpWidget(const MyApp());
  await avanzar(tester, 300);
  if (admin) {
    await tester.tap(find.text('Administrador'));
    await avanzar(tester, 300);
    await tester.tap(find.text('Entrar al panel'));
  } else {
    await tester.tap(find.text('Entrar'));
  }
  await avanzar(tester, 2500);
}

void main() {
  for (final (nombre, size) in [
    ('celular', const Size(390, 844)),
    ('escritorio', const Size(1440, 900)),
  ]) {
    group('En $nombre', () {
      testWidgets('ciudadano: inicio, reportar, avisos, reportes, perfil', (
        tester,
      ) async {
        await tamano(tester, size);
        await entrar(tester, admin: false);

        expect(find.text('Avisos activos'), findsOneWidget);
        expect(find.text('Col. Centro · Corte programado'), findsOneWidget);
        expect(find.text('Corte programado'), findsWidgets);

        // Formulario: validación de campos obligatorios.
        await tester.tap(find.text('Reportar ahora'));
        await avanzar(tester, 600);
        expect(find.text('Nuevo reporte'), findsOneWidget);
        await tester.ensureVisible(find.text('Enviar reporte'));
        await tester.tap(find.text('Enviar reporte'));
        await tester.pump();
        expect(find.text('Selecciona un tipo de problema'), findsOneWidget);
        expect(find.text('Indica la ubicación del problema'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5)); // cerrar hoja
        await avanzar(tester, 600);

        await tester.tap(find.text('Avisos').last);
        await avanzar(tester, 300);
        await tester.tap(find.text('Todas'));
        await avanzar(tester, 300);
        expect(find.text('Servicio restablecido'), findsOneWidget);

        await tester.tap(find.text('Mis reportes').last);
        await avanzar(tester, 300);
        expect(find.textContaining('Activos ('), findsOneWidget);

        await tester.tap(find.text('Perfil'));
        await avanzar(tester, 300);
        expect(find.text('Cerrar sesión'), findsOneWidget);
      });

      testWidgets('administrador: panel, reportes y avisos', (tester) async {
        await tamano(tester, size);
        await entrar(tester, admin: true);

        expect(find.text('Reportes totales'), findsOneWidget);
        expect(find.text('Reportes por estado'), findsOneWidget);

        await tester.tap(find.text('Reportes').first);
        await avanzar(tester, 300);
        expect(find.textContaining('Mostrando'), findsOneWidget);

        // Filtrar por pendientes: el contador del chip coincide con la lista.
        // (Los datos simulados se comparten entre pruebas, así que no se
        // asume un número fijo.)
        final chip = find.textContaining('Pendiente (').first;
        final n = RegExp(
          r'\((\d+)\)',
        ).firstMatch(tester.widget<Text>(chip).data!)!.group(1);
        await tester.tap(chip);
        await avanzar(tester, 300);
        expect(find.textContaining('Mostrando $n de'), findsOneWidget);
        await tester.tap(find.textContaining('Todos (').first);
        await avanzar(tester, 300);

        // Abrir detalle y cambiar a un estado distinto del actual.
        // Centrar la fila para que no quede detrás de la barra inferior.
        await tester.ensureVisible(find.textContaining('Fuga constante').first);
        await tester.pump();
        await Scrollable.ensureVisible(
          tester.element(find.textContaining('Fuga constante').first),
          alignment: 0.4,
        );
        await avanzar(tester, 300);
        await tester.tap(find.textContaining('Fuga constante').first);
        await avanzar(tester, 500);
        expect(find.text('Guardar cambios'), findsOneWidget);
        final otro = find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byWidgetPredicate(
                (w) => w is ChoiceChip && !w.selected,
                description: 'estado no seleccionado',
              ),
            )
            .first;
        await tester.ensureVisible(otro);
        await tester.tap(otro);
        await tester.pump();
        await tester.tap(find.text('Guardar cambios'));
        await avanzar(tester, 2000);
        expect(find.text('Reporte #8 actualizado'), findsOneWidget);

        await tester.tap(find.text('Avisos').first);
        await avanzar(tester, 300);
        await tester.tap(find.text('Nuevo aviso'));
        await avanzar(tester, 500);
        await tester.tap(find.text('Publicar'));
        await tester.pump();
        expect(find.text('Campo obligatorio'), findsWidgets);
      });
    });
  }
}
