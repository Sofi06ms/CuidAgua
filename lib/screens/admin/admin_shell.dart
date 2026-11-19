import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/comunes.dart';
import '../../widgets/navegacion.dart';
import '../login_screen.dart';
import 'admin_avisos.dart';
import 'admin_panel.dart';
import 'admin_reportes.dart';

/// App del administrador: barra lateral en pantallas anchas,
/// barra inferior flotante en pantallas angostas.
class AdminShell extends StatefulWidget {
  final Usuario usuario;

  const AdminShell({super.key, required this.usuario});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _api = ApiService();

  int _seccion = 0;
  bool _cargando = true;
  Object? _error;
  List<Reporte> _reportes = [];
  List<AvisoSuministro> _avisos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await Future.wait([
        _api.consultarReportes(),
        _api.obtenerAvisosSuministro(),
      ]);
      if (!mounted) return;
      setState(() {
        _reportes = res[0] as List<Reporte>;
        _avisos = res[1] as List<AvisoSuministro>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _cerrarSesion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  int get _pendientes =>
      _reportes.where((r) => r.estado == EstadoReporte.pendiente).length;

  Widget _contenido() {
    switch (_seccion) {
      case 1:
        return AdminReportes(
          api: _api,
          reportes: _reportes,
          cargando: _cargando,
          error: _error,
          onCambio: _cargar,
        );
      case 2:
        return AdminAvisos(
          api: _api,
          avisos: _avisos,
          cargando: _cargando,
          error: _error,
          onCambio: _cargar,
        );
      default:
        return AdminPanel(
          usuario: widget.usuario,
          reportes: _reportes,
          avisos: _avisos,
          cargando: _cargando,
          error: _error,
          onRefresh: _cargar,
          onVerReportes: () => setState(() => _seccion = 1),
          onVerAvisos: () => setState(() => _seccion = 2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final destinos = [
      const DestinoNav(
        icono: Icons.dashboard_outlined,
        iconoActivo: Icons.dashboard_rounded,
        etiqueta: 'Panel',
      ),
      DestinoNav(
        icono: Icons.assignment_outlined,
        iconoActivo: Icons.assignment_rounded,
        etiqueta: 'Reportes',
        contador: _pendientes,
      ),
      const DestinoNav(
        icono: Icons.campaign_outlined,
        iconoActivo: Icons.campaign_rounded,
        etiqueta: 'Avisos',
      ),
    ];

    if (ancho) {
      return Scaffold(
        body: Row(
          children: [
            BarraLateral(
              destinos: destinos,
              seleccion: _seccion,
              etiquetaApp: 'PANEL ADMINISTRATIVO',
              onSeleccion: (i) => setState(() => _seccion = i),
              pie: PieLateral(
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.aqua,
                  child: Text(
                    widget.usuario.iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                titulo: widget.usuario.nombre,
                subtitulo: 'Administrador',
                iconoAccion: Icons.logout_rounded,
                tooltip: 'Cerrar sesión',
                onTap: _cerrarSesion,
              ),
            ),
            Expanded(child: _contenido()),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BarraSuperiorMovil(
              etiqueta: 'ADMIN',
              acciones: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            Expanded(child: _contenido()),
          ],
        ),
      ),
      bottomNavigationBar: NavInferior(
        destinos: destinos,
        seleccion: _seccion,
        onSeleccion: (i) => setState(() => _seccion = i),
      ),
    );
  }
}

/// Estructura común para las secciones del panel: encabezado y contenido
/// con ancho máximo.
class AdminPagina extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final List<Widget> acciones;
  final List<Widget> children;
  final Widget? encabezado;
  final Future<void> Function() onRefresh;

  const AdminPagina({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.children,
    required this.onRefresh,
    this.icono = Icons.dashboard_rounded,
    this.color = AppTheme.azul,
    this.acciones = const [],
    this.encabezado,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= anchoEscritorio;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          ancho ? 28 : 16,
          ancho ? 24 : 8,
          ancho ? 28 : 16,
          ancho ? 40 : 100,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  encabezado ??
                      EncabezadoPagina(
                        icono: icono,
                        titulo: titulo,
                        subtitulo: subtitulo,
                        color: color,
                        acciones: acciones,
                      ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
