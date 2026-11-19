import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/comunes.dart';
import '../../widgets/estado_widgets.dart';
import 'admin_shell.dart';

/// Resumen general: indicadores, distribución de reportes y pendientes.
class AdminPanel extends StatelessWidget {
  final Usuario usuario;
  final List<Reporte> reportes;
  final List<AvisoSuministro> avisos;
  final bool cargando;
  final Object? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onVerReportes;
  final VoidCallback onVerAvisos;

  const AdminPanel({
    super.key,
    required this.usuario,
    required this.reportes,
    required this.avisos,
    required this.cargando,
    required this.error,
    required this.onRefresh,
    required this.onVerReportes,
    required this.onVerAvisos,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = usuario.nombre.split(' ').first;

    if (cargando && reportes.isEmpty) {
      return AdminPagina(
        titulo: 'Hola, $nombre',
        subtitulo: 'Cargando el resumen…',
        encabezado: BannerBienvenida(
          titulo: _saludo(),
          subtitulo: '$nombre, estamos preparando tu resumen…',
        ),
        onRefresh: onRefresh,
        children: const [LoadingList(count: 4)],
      );
    }
    if (error != null) {
      return AdminPagina(
        titulo: 'Hola, $nombre',
        subtitulo: 'Resumen de incidencias',
        icono: Icons.cloud_off_rounded,
        onRefresh: onRefresh,
        children: [
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar la información',
            detalle: 'Verifica que el servidor esté disponible.',
            actionLabel: 'Reintentar',
            onAction: onRefresh,
            esError: true,
          ),
        ],
      );
    }

    int contar(EstadoReporte e) => reportes.where((r) => r.estado == e).length;
    final total = reportes.length;
    final pendientes = contar(EstadoReporte.pendiente);
    final enAtencion =
        contar(EstadoReporte.enRevision) + contar(EstadoReporte.enProceso);
    final resueltos = contar(EstadoReporte.resuelto);
    final tasa = total == 0 ? 0 : (resueltos * 100 / total).round();

    final urgentes = reportes
        .where(
          (r) =>
              r.estado != EstadoReporte.resuelto &&
              r.prioridad == Prioridad.alta,
        )
        .toList();

    Map<String, int> agrupar(String Function(Reporte) clave) {
      final m = <String, int>{};
      for (final r in reportes) {
        m[clave(r)] = (m[clave(r)] ?? 0) + 1;
      }
      final entradas = m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(entradas);
    }

    final kpis = [
      TarjetaEstadistica(
        icono: Icons.inbox_rounded,
        color: AppTheme.azul,
        valor: '$total',
        etiqueta: 'Reportes totales',
        onTap: onVerReportes,
      ),
      TarjetaEstadistica(
        icono: Icons.schedule_rounded,
        color: AppTheme.naranja,
        valor: '$pendientes',
        etiqueta: 'Pendientes',
        nota: pendientes > 0 ? 'Requieren revisión' : 'Al día',
        onTap: onVerReportes,
      ),
      TarjetaEstadistica(
        icono: Icons.construction_rounded,
        color: const Color(0xFF7B5CE0),
        valor: '$enAtencion',
        etiqueta: 'En atención',
        onTap: onVerReportes,
      ),
      TarjetaEstadistica(
        icono: Icons.check_circle_rounded,
        color: AppTheme.menta,
        valor: '$resueltos',
        etiqueta: 'Resueltos',
        nota: '$tasa% del total',
        onTap: onVerReportes,
      ),
    ];

    return AdminPagina(
      titulo: 'Panel',
      subtitulo: 'Resumen de incidencias',
      onRefresh: onRefresh,
      encabezado: BannerBienvenida(
        titulo: _saludo(),
        subtitulo: '$nombre, así va la atención del agua hoy',
        extra: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PildoraBanner(
              icono: pendientes > 0
                  ? Icons.priority_high_rounded
                  : Icons.check_rounded,
              color: pendientes > 0 ? AppTheme.naranja : AppTheme.menta,
              texto: pendientes > 0
                  ? '$pendientes pendientes por revisar'
                  : 'Todo al día',
              onTap: onVerReportes,
            ),
            if (urgentes.isNotEmpty)
              PildoraBanner(
                icono: Icons.local_fire_department_rounded,
                color: const Color(0xFFE5484D),
                texto: '${urgentes.length} urgentes',
                onTap: onVerReportes,
              ),
          ],
        ),
      ),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 4 : 2;
            final gap = c.maxWidth < 500 ? 12.0 : 18.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final k in kpis) SizedBox(width: w, child: k)],
            );
          },
        ),
        const SizedBox(height: 20),
        BannerAccion(
          icono: Icons.campaign_rounded,
          titulo: '¿Hay un corte o mantenimiento?',
          subtitulo: 'Publica un aviso y la ciudadanía lo verá al instante',
          boton: 'Publicar aviso',
          iconoBoton: Icons.add_rounded,
          onPressed: onVerAvisos,
        ),
        const SizedBox(height: 24),
        _DosColumnas(
          izquierda: _Panel(
            icono: Icons.donut_large_rounded,
            titulo: 'Reportes por estado',
            child: _Barras(
              datos: [
                for (final e in EstadoReporte.values)
                  _Dato(e.etiqueta, contar(e), color: e.color, icono: e.icono),
              ],
              total: total,
            ),
          ),
          derecha: _Panel(
            icono: Icons.map_rounded,
            titulo: 'Reportes por colonia',
            child: _Barras(
              datos: [
                for (final e in agrupar((r) => r.colonia).entries)
                  _Dato(e.key, e.value),
              ],
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DosColumnas(
          izquierda: _Panel(
            icono: Icons.local_fire_department_rounded,
            color: const Color(0xFFE5484D),
            titulo: 'Atención urgente',
            subtitulo: 'Prioridad alta sin resolver',
            accion: TextButton(
              onPressed: onVerReportes,
              child: const Text('Ver reportes'),
            ),
            child: urgentes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Sin reportes urgentes 🎉')),
                  )
                : Column(
                    children: [
                      for (final r in urgentes.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Prioridad.alta.color.withValues(
                              alpha: context.esOscuro ? 0.14 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: IconoCirculo(
                                icono: r.tipo.icono,
                                color: Prioridad.alta.color,
                                tamano: 42,
                              ),
                              title: Text(
                                r.descripcion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text('${r.colonia} · ${r.fecha}'),
                              trailing: EstadoChip(
                                estado: r.estado,
                                compacto: true,
                              ),
                              onTap: onVerReportes,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          derecha: _Panel(
            icono: Icons.category_rounded,
            titulo: 'Por tipo de problema',
            child: _Barras(
              datos: [
                for (final e in agrupar((r) => r.tipo.etiqueta).entries)
                  _Dato(e.key, e.value),
              ],
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 28),
        TituloSeccion(
          icono: Icons.campaign_rounded,
          titulo: 'Avisos publicados',
          accion: 'Gestionar',
          onAccion: onVerAvisos,
        ),
        if (avisos.isEmpty)
          const EstadoMensaje(
            icon: Icons.campaign_outlined,
            titulo: 'No hay avisos publicados',
          )
        else
          for (final a in avisos.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AvisoCard(aviso: a),
            ),
      ],
    );
  }

  static String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _DosColumnas extends StatelessWidget {
  final Widget izquierda;
  final Widget derecha;

  const _DosColumnas({required this.izquierda, required this.derecha});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 800) {
          return Column(
            children: [izquierda, const SizedBox(height: 20), derecha],
          );
        }
        // Sin IntrinsicHeight: las barras usan LayoutBuilder.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: izquierda),
            const SizedBox(width: 20),
            Expanded(child: derecha),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final IconData icono;
  final Color? color;
  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final Widget child;

  const _Panel({
    required this.icono,
    required this.titulo,
    required this.child,
    this.color,
    this.subtitulo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconoCaja(
                  icono: icono,
                  color: color ?? AppTheme.azul,
                  tamano: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?accion,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _Dato {
  final String etiqueta;
  final int valor;
  final Color? color;
  final IconData? icono;

  const _Dato(this.etiqueta, this.valor, {this.color, this.icono});
}

/// Barras horizontales delgadas con etiqueta, valor y tooltip.
class _Barras extends StatelessWidget {
  final List<_Dato> datos;
  final int total;

  const _Barras({required this.datos, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maximo = datos.fold<int>(0, (m, d) => d.valor > m ? d.valor : m);

    if (datos.isEmpty || maximo == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Sin datos',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        for (final d in datos)
          Tooltip(
            message:
                '${d.etiqueta}: ${d.valor} (${(d.valor * 100 / total).round()}%)',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 128,
                    child: Row(
                      children: [
                        if (d.icono != null) ...[
                          Icon(d.icono, size: 16, color: d.color),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            d.etiqueta,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 12,
                            width: c.maxWidth * d.valor / maximo,
                            decoration: BoxDecoration(
                              color: d.color ?? scheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${d.valor}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
