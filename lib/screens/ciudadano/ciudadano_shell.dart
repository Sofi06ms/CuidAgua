import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/comunes.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/navegacion.dart';
import '../../widgets/nuevo_reporte_sheet.dart';
import '../login_screen.dart';

/// App del ciudadano: inicio, avisos, mis reportes y perfil.
class CiudadanoShell extends StatefulWidget {
  final Usuario usuario;

  const CiudadanoShell({super.key, required this.usuario});

  @override
  State<CiudadanoShell> createState() => _CiudadanoShellState();
}

class _CiudadanoShellState extends State<CiudadanoShell> {
  final _api = ApiService();

  int _tab = 0;
  bool _cargando = true;
  Object? _error;
  List<Reporte> _reportes = [];
  List<AvisoSuministro> _avisos = [];

  Usuario get _usuario => widget.usuario;

  List<Reporte> get _misReportes =>
      _reportes.where((r) => r.ciudadano == _usuario.nombre).toList();

  List<AvisoSuministro> get _avisosMiColonia =>
      _avisos.where((a) => a.coloniaAfectada == _usuario.colonia).toList();

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

  Future<void> _reportar([TipoProblema? tipo]) async {
    final enviado = await NuevoReporteSheet.mostrar(
      context,
      api: _api,
      usuario: _usuario,
      tipoInicial: tipo,
    );
    if (enviado != true || !mounted) return;

    setState(() => _tab = 2);
    _cargar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E8E55),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Gracias! Tu reporte fue enviado. '
                'Te avisaremos cuando cambie de estado.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= anchoEscritorio;

    final destinos = [
      const DestinoNav(
        icono: Icons.home_outlined,
        iconoActivo: Icons.home_rounded,
        etiqueta: 'Inicio',
      ),
      DestinoNav(
        icono: Icons.notifications_outlined,
        iconoActivo: Icons.notifications_rounded,
        etiqueta: 'Avisos',
        contador: _avisosMiColonia.length,
      ),
      const DestinoNav(
        icono: Icons.assignment_outlined,
        iconoActivo: Icons.assignment_rounded,
        etiqueta: 'Mis reportes',
      ),
      const DestinoNav(
        icono: Icons.person_outline_rounded,
        iconoActivo: Icons.person_rounded,
        etiqueta: 'Perfil',
      ),
    ];

    final paginas = IndexedStack(
      index: _tab,
      children: [
        _InicioCiudadano(
          usuario: _usuario,
          cargando: _cargando,
          error: _error,
          misReportes: _misReportes,
          avisos: _avisos,
          avisosMiColonia: _avisosMiColonia,
          onRefresh: _cargar,
          onReportar: _reportar,
          onIrA: (i) => setState(() => _tab = i),
        ),
        _AvisosCiudadano(
          usuario: _usuario,
          cargando: _cargando,
          error: _error,
          avisos: _avisos,
          onRefresh: _cargar,
        ),
        _MisReportes(
          cargando: _cargando,
          error: _error,
          reportes: _misReportes,
          onRefresh: _cargar,
          onReportar: () => _reportar(),
        ),
        _Perfil(
          usuario: _usuario,
          totalReportes: _misReportes.length,
          resueltos: _misReportes
              .where((r) => r.estado == EstadoReporte.resuelto)
              .length,
          avisos: _avisosMiColonia.length,
          onCerrarSesion: _cerrarSesion,
        ),
      ],
    );

    final fab = (_tab == 1 || _tab == 2)
        ? FloatingActionButton.extended(
            onPressed: () => _reportar(),
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('Reportar'),
          )
        : null;

    if (ancho) {
      return Scaffold(
        floatingActionButton: fab,
        body: Row(
          children: [
            BarraLateral(
              destinos: destinos,
              seleccion: _tab,
              onSeleccion: (i) => setState(() => _tab = i),
              pie: PieLateral(
                avatar: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                titulo: 'Col. ${_usuario.colonia}',
                subtitulo: 'Comunidad CuidAgua',
                iconoAccion: Icons.keyboard_arrow_right_rounded,
                tooltip: 'Ver mi perfil',
                onTap: () => setState(() => _tab = 3),
              ),
            ),
            Expanded(child: paginas),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: fab,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BarraSuperiorMovil(
              acciones: [
                IconButton(
                  tooltip: 'Avisos de mi colonia',
                  onPressed: () => setState(() => _tab = 1),
                  icon: Badge(
                    isLabelVisible: _avisosMiColonia.isNotEmpty,
                    label: Text('${_avisosMiColonia.length}'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _tab = 3),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.azul,
                      child: Text(
                        _usuario.iniciales,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: paginas),
          ],
        ),
      ),
      bottomNavigationBar: NavInferior(
        destinos: destinos,
        seleccion: _tab,
        onSeleccion: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Lista desplazable con ancho máximo y "jalar para actualizar".
class _Contenedor extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  const _Contenedor({required this.onRefresh, required this.children});

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
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dos widgets lado a lado; en pantallas angostas, uno debajo del otro.
class _Par extends StatelessWidget {
  final Widget a;
  final Widget b;
  final bool siempreFila;

  const _Par({required this.a, required this.b, this.siempreFila = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final gap = c.maxWidth < 500 ? 12.0 : 20.0;
        if (siempreFila) {
          // Sin IntrinsicHeight: las tarjetas de estadística usan
          // LayoutBuilder, que no admite medidas intrínsecas.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              SizedBox(width: gap),
              Expanded(child: b),
            ],
          );
        }
        if (c.maxWidth < 720) {
          return Column(
            children: [
              a,
              SizedBox(height: gap),
              b,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              SizedBox(width: gap),
              Expanded(child: b),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════ INICIO ═══════════════════════════════

class _InicioCiudadano extends StatelessWidget {
  final Usuario usuario;
  final bool cargando;
  final Object? error;
  final List<Reporte> misReportes;
  final List<AvisoSuministro> avisos;
  final List<AvisoSuministro> avisosMiColonia;
  final Future<void> Function() onRefresh;
  final void Function([TipoProblema?]) onReportar;
  final ValueChanged<int> onIrA;

  const _InicioCiudadano({
    required this.usuario,
    required this.cargando,
    required this.error,
    required this.misReportes,
    required this.avisos,
    required this.avisosMiColonia,
    required this.onRefresh,
    required this.onReportar,
    required this.onIrA,
  });

  static String saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final activos = misReportes
        .where((r) => r.estado != EstadoReporte.resuelto)
        .toList();
    final nombre = usuario.nombre.split(' ').first;

    // Primero los avisos de mi colonia, luego los vigentes de otras.
    final destacados = [
      ...avisosMiColonia,
      ...avisos.where(
        (a) =>
            a.coloniaAfectada != usuario.colonia &&
            a.tipo != TipoAviso.restablecido,
      ),
    ].take(3).toList();

    return _Contenedor(
      onRefresh: onRefresh,
      children: [
        BannerBienvenida(
          titulo: saludo(),
          subtitulo: '$nombre, así está el agua en tu comunidad hoy',
          extra: cargando
              ? null
              : _EstadoSuministro(
                  colonia: usuario.colonia,
                  avisos: avisosMiColonia,
                  error: error,
                  onTap: () => onIrA(1),
                ),
        ),
        const SizedBox(height: 20),
        _Par(
          siempreFila: true,
          a: TarjetaEstadistica(
            icono: Icons.water_drop_rounded,
            color: AppTheme.azul,
            valor: cargando ? '–' : '${avisosMiColonia.length}',
            etiqueta: 'Avisos activos',
            onTap: () => onIrA(1),
          ),
          b: TarjetaEstadistica(
            icono: Icons.description_rounded,
            color: AppTheme.menta,
            valor: cargando ? '–' : '${misReportes.length}',
            etiqueta: 'Mis reportes',
            onTap: () => onIrA(2),
          ),
        ),
        const SizedBox(height: 20),
        BannerAccion(
          icono: Icons.warning_rounded,
          titulo: '¿Viste una fuga o un problema?',
          subtitulo: 'Repórtalo en menos de un minuto',
          boton: 'Reportar ahora',
          onPressed: () => onReportar(),
        ),
        const SizedBox(height: 28),
        TituloSeccion(
          icono: Icons.campaign_rounded,
          titulo: 'Avisos de suministro',
          accion: 'Ver todos',
          onAccion: () => onIrA(1),
        ),
        if (cargando)
          const LoadingList(count: 2)
        else if (error != null)
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar los avisos',
            detalle: 'Revisa tu conexión e inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: onRefresh,
            esError: true,
          )
        else if (destacados.isEmpty)
          const EstadoMensaje(
            icon: Icons.check_circle_outline_rounded,
            titulo: 'Todo en orden',
            detalle: 'No hay cortes ni avisos de suministro por ahora.',
          )
        else
          for (final a in destacados)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AvisoCard(aviso: a),
            ),
        const SizedBox(height: 20),
        const TituloSeccion(
          icono: Icons.touch_app_rounded,
          titulo: '¿Qué quieres reportar?',
        ),
        _AccionesRapidas(onReportar: onReportar),
        const SizedBox(height: 28),
        TituloSeccion(
          icono: Icons.timeline_rounded,
          titulo: 'Seguimiento de mis reportes',
          accion: misReportes.isEmpty ? null : 'Ver todos',
          onAccion: () => onIrA(2),
        ),
        if (cargando)
          const LoadingList(count: 1)
        else if (error != null)
          const SizedBox.shrink()
        else if (activos.isEmpty)
          EstadoMensaje(
            icon: Icons.verified_rounded,
            titulo: 'No tienes reportes activos',
            detalle: misReportes.isEmpty
                ? 'Cuando reportes un problema podrás seguir su avance aquí.'
                : 'Todos tus reportes han sido resueltos. ¡Gracias por participar!',
          )
        else
          for (final r in activos.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReporteSeguimientoCard(reporte: r),
            ),
        const SizedBox(height: 20),
        _Par(
          a: _ImpactoCard(
            total: misReportes.length,
            resueltos: misReportes
                .where((r) => r.estado == EstadoReporte.resuelto)
                .length,
          ),
          b: const _ConsejoDelDia(),
        ),
      ],
    );
  }
}

class _EstadoSuministro extends StatelessWidget {
  final String colonia;
  final List<AvisoSuministro> avisos;
  final Object? error;
  final VoidCallback onTap;

  const _EstadoSuministro({
    required this.colonia,
    required this.avisos,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AvisoSuministro? principal =
        avisos.where((a) => a.tipo == TipoAviso.corte).firstOrNull ??
        avisos.where((a) => a.tipo != TipoAviso.restablecido).firstOrNull;

    final (String texto, IconData icono, Color color) = error != null
        ? ('Sin conexión', Icons.cloud_off_rounded, Colors.grey)
        : principal == null
        ? ('Servicio normal', Icons.check_rounded, AppTheme.menta)
        : (
            principal.tipo.etiqueta,
            Icons.priority_high_rounded,
            AvisoCard.colorDe(principal.tipo),
          );

    return PildoraBanner(
      icono: icono,
      color: color,
      texto: 'Col. $colonia · $texto',
      onTap: onTap,
    );
  }
}

class _AccionesRapidas extends StatelessWidget {
  final void Function([TipoProblema?]) onReportar;

  const _AccionesRapidas({required this.onReportar});

  static const _acciones = [
    (TipoProblema.fuga, Color(0xFF1E6FE8)),
    (TipoProblema.sinSuministro, Color(0xFFE5484D)),
    (TipoProblema.bajaPresion, Color(0xFFFF7A3D)),
    (TipoProblema.aguaTurbia, Color(0xFF8D6E63)),
    (TipoProblema.drenaje, Color(0xFF7B5CE0)),
    (TipoProblema.otro, Color(0xFF5B7896)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth > 700 ? 6 : 3;
        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columnas == 6 ? 1.0 : 0.92,
          children: [
            for (final (tipo, color) in _acciones)
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onReportar(tipo),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconoCirculo(
                          icono: tipo.icono,
                          color: color,
                          tamano: 56,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tipo.etiqueta,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ImpactoCard extends StatelessWidget {
  final int total;
  final int resueltos;

  const _ImpactoCard({required this.total, required this.resueltos});

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final tinta = isDark ? Colors.white : const Color(0xFF0E4D2E);
    // Estimación ilustrativa: ~1,500 L ahorrados por fuga/problema resuelto.
    final litros = resueltos * 1500;

    Widget dato(String valor, String etiqueta) => Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: tinta,
            ),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tinta.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF123B2C), Color(0xFF0F2F3A)]
              : const [Color(0xFFE3F8EC), Color(0xFFD2F1E4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoCirculo(
                icono: Icons.eco_rounded,
                color: AppTheme.menta,
                tamano: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu impacto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tinta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              dato('$total', 'Reportes\nenviados'),
              dato('$resueltos', 'Problemas\nresueltos'),
              dato(
                litros >= 1000
                    ? '${(litros / 1000).toStringAsFixed(1)}k'
                    : '$litros',
                'Litros que\nayudaste a cuidar*',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '*Estimación aproximada por problema resuelto.',
            style: TextStyle(fontSize: 11, color: tinta.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _ConsejoDelDia extends StatelessWidget {
  const _ConsejoDelDia();

  static const _consejos = [
    'Cerrar la llave mientras te cepillas los dientes ahorra hasta 12 litros por minuto.',
    'Una llave que gotea puede desperdiciar más de 30 litros al día. ¡Repárala o repórtala!',
    'Reutiliza el agua con la que lavas frutas y verduras para regar tus plantas.',
    'Una ducha de 5 minutos usa hasta 4 veces menos agua que llenar la tina.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.esOscuro;
    final tinta = isDark ? Colors.white : const Color(0xFF5A3B00);
    final consejo = _consejos[DateTime.now().day % _consejos.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF3A2D10), Color(0xFF2E2A18)]
              : const [Color(0xFFFFF4D9), Color(0xFFFFEBC2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoCirculo(
                icono: Icons.lightbulb_rounded,
                color: AppTheme.ambar,
                tamano: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Consejo del día',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tinta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            consejo,
            style: TextStyle(fontSize: 15.5, height: 1.4, color: tinta),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════ AVISOS ═══════════════════════════════

class _AvisosCiudadano extends StatefulWidget {
  final Usuario usuario;
  final bool cargando;
  final Object? error;
  final List<AvisoSuministro> avisos;
  final Future<void> Function() onRefresh;

  const _AvisosCiudadano({
    required this.usuario,
    required this.cargando,
    required this.error,
    required this.avisos,
    required this.onRefresh,
  });

  @override
  State<_AvisosCiudadano> createState() => _AvisosCiudadanoState();
}

class _AvisosCiudadanoState extends State<_AvisosCiudadano> {
  bool _soloMiColonia = true;

  @override
  Widget build(BuildContext context) {
    final lista = _soloMiColonia
        ? widget.avisos
              .where((a) => a.coloniaAfectada == widget.usuario.colonia)
              .toList()
        : widget.avisos;

    return _Contenedor(
      onRefresh: widget.onRefresh,
      children: [
        const EncabezadoPagina(
          icono: Icons.notifications_active_rounded,
          titulo: 'Avisos',
          subtitulo: 'Cortes, mantenimientos y horarios de suministro',
        ),
        const SizedBox(height: 18),
        FiltroPildoras<bool>(
          opciones: [
            (true, 'Col. ${widget.usuario.colonia}', Icons.home_rounded),
            (false, 'Todas', Icons.public_rounded),
          ],
          seleccion: _soloMiColonia,
          onChanged: (v) => setState(() => _soloMiColonia = v),
        ),
        const SizedBox(height: 16),
        if (widget.cargando)
          const LoadingList()
        else if (widget.error != null)
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar los avisos',
            detalle: 'Revisa tu conexión e inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: widget.onRefresh,
            esError: true,
          )
        else if (lista.isEmpty)
          const EstadoMensaje(
            icon: Icons.check_circle_outline_rounded,
            titulo: 'Todo en orden',
            detalle: 'No hay avisos de suministro por ahora.',
          )
        else
          for (final a in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AvisoCard(aviso: a),
            ),
      ],
    );
  }
}

// ═══════════════════════════════ MIS REPORTES ═══════════════════════════════

class _MisReportes extends StatefulWidget {
  final bool cargando;
  final Object? error;
  final List<Reporte> reportes;
  final Future<void> Function() onRefresh;
  final VoidCallback onReportar;

  const _MisReportes({
    required this.cargando,
    required this.error,
    required this.reportes,
    required this.onRefresh,
    required this.onReportar,
  });

  @override
  State<_MisReportes> createState() => _MisReportesState();
}

class _MisReportesState extends State<_MisReportes> {
  int _filtro = 0; // 0 activos · 1 resueltos · 2 todos

  @override
  Widget build(BuildContext context) {
    final r = widget.reportes;
    final activos = r.where((x) => x.estado != EstadoReporte.resuelto).toList();
    final resueltos = r
        .where((x) => x.estado == EstadoReporte.resuelto)
        .toList();
    final lista = [activos, resueltos, r][_filtro];

    return _Contenedor(
      onRefresh: widget.onRefresh,
      children: [
        const EncabezadoPagina(
          icono: Icons.assignment_rounded,
          titulo: 'Mis reportes',
          subtitulo: 'Consulta en qué etapa va cada uno',
          color: AppTheme.menta,
        ),
        const SizedBox(height: 18),
        FiltroPildoras<int>(
          opciones: [
            (0, 'Activos (${activos.length})', Icons.autorenew_rounded),
            (1, 'Resueltos (${resueltos.length})', Icons.check_circle_rounded),
            (2, 'Todos (${r.length})', null),
          ],
          seleccion: _filtro,
          onChanged: (v) => setState(() => _filtro = v),
        ),
        const SizedBox(height: 16),
        if (widget.cargando)
          const LoadingList()
        else if (widget.error != null)
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar tus reportes',
            detalle: 'Revisa tu conexión e inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: widget.onRefresh,
            esError: true,
          )
        else if (lista.isEmpty)
          EstadoMensaje(
            icon: Icons.inbox_outlined,
            titulo: _filtro == 1
                ? 'Aún no hay reportes resueltos'
                : 'No tienes reportes aquí',
            detalle: 'Si ves una fuga o un problema, repórtalo en segundos.',
            actionLabel: 'Crear reporte',
            onAction: widget.onReportar,
          )
        else
          for (final rep in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReporteSeguimientoCard(reporte: rep),
            ),
      ],
    );
  }
}

/// Tarjeta de reporte con su línea de seguimiento.
class ReporteSeguimientoCard extends StatelessWidget {
  final Reporte reporte;

  const ReporteSeguimientoCard({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = reporte.estado.color;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconoCirculo(
                          icono: reporte.tipo.icono,
                          color: AppTheme.azul,
                          tamano: 52,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reporte.tipo.etiqueta} · #${reporte.id}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reporte.descripcion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        EstadoChip(estado: reporte.estado, compacto: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pastilla(
                          icon: Icons.location_on_rounded,
                          texto: reporte.ubicacion,
                        ),
                        Pastilla(
                          icon: Icons.calendar_month_rounded,
                          texto: reporte.fecha,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SeguimientoReporte(estado: reporte.estado),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════ PERFIL ═══════════════════════════════

class _Perfil extends StatefulWidget {
  final Usuario usuario;
  final int totalReportes;
  final int resueltos;
  final int avisos;
  final VoidCallback onCerrarSesion;

  const _Perfil({
    required this.usuario,
    required this.totalReportes,
    required this.resueltos,
    required this.avisos,
    required this.onCerrarSesion,
  });

  @override
  State<_Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<_Perfil> {
  bool _notificaciones = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = widget.usuario;

    Widget opcion({
      required IconData icono,
      required Color color,
      required String titulo,
      String? subtitulo,
      Widget? trailing,
      VoidCallback? onTap,
    }) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: IconoCaja(icono: icono, color: color, tamano: 42),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitulo == null ? null : Text(subtitulo),
      trailing: trailing,
      onTap: onTap,
    );

    return _Contenedor(
      onRefresh: () async {},
      children: [
        // Tarjeta de identidad
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.degradadoAccion,
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 180,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFDCEBFF),
                          child: Text(
                            u.iniciales,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.azul,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              u.correo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Col. ${u.colonia}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Par(
          siempreFila: true,
          a: TarjetaEstadistica(
            icono: Icons.description_rounded,
            color: AppTheme.azul,
            valor: '${widget.totalReportes}',
            etiqueta: 'Reportes enviados',
          ),
          b: TarjetaEstadistica(
            icono: Icons.check_circle_rounded,
            color: AppTheme.menta,
            valor: '${widget.resueltos}',
            etiqueta: 'Resueltos',
          ),
        ),
        const SizedBox(height: 22),
        const TituloSeccion(icono: Icons.tune_rounded, titulo: 'Preferencias'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              opcion(
                icono: Icons.notifications_active_rounded,
                color: AppTheme.azul,
                titulo: 'Avisos de mi colonia',
                subtitulo: 'Cortes y cambios en mis reportes',
                trailing: Switch(
                  value: _notificaciones,
                  onChanged: (v) => setState(() => _notificaciones = v),
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              opcion(
                icono: Icons.campaign_rounded,
                color: AppTheme.naranja,
                titulo: 'Avisos activos',
                trailing: Text(
                  '${widget.avisos}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              opcion(
                icono: Icons.help_rounded,
                color: const Color(0xFF7B5CE0),
                titulo: 'Ayuda y preguntas frecuentes',
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: widget.onCerrarSesion,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            minimumSize: const Size.fromHeight(54),
            side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
