import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/comunes.dart';
import '../../widgets/estado_widgets.dart';
import 'admin_shell.dart';

/// Gestión de reportes: búsqueda, filtros y cambio de estado/prioridad.
class AdminReportes extends StatefulWidget {
  final ApiService api;
  final List<Reporte> reportes;
  final bool cargando;
  final Object? error;
  final Future<void> Function() onCambio;

  const AdminReportes({
    super.key,
    required this.api,
    required this.reportes,
    required this.cargando,
    required this.error,
    required this.onCambio,
  });

  @override
  State<AdminReportes> createState() => _AdminReportesState();
}

class _AdminReportesState extends State<AdminReportes> {
  final _busqueda = TextEditingController();
  EstadoReporte? _estado;
  Prioridad? _prioridad;
  String? _colonia;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Reporte> get _filtrados {
    final q = _busqueda.text.trim().toLowerCase();
    return widget.reportes.where((r) {
      if (_estado != null && r.estado != _estado) return false;
      if (_prioridad != null && r.prioridad != _prioridad) return false;
      if (_colonia != null && r.colonia != _colonia) return false;
      if (q.isEmpty) return true;
      return r.descripcion.toLowerCase().contains(q) ||
          r.ubicacion.toLowerCase().contains(q) ||
          r.ciudadano.toLowerCase().contains(q) ||
          '#${r.id}'.contains(q);
    }).toList();
  }

  Future<void> _actualizar(
    Reporte r, {
    EstadoReporte? estado,
    Prioridad? prioridad,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.api.actualizarReporte(
      r.id,
      estado: estado,
      prioridad: prioridad,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Reporte #${r.id} actualizado'
              : 'No se pudo actualizar el reporte #${r.id}',
        ),
      ),
    );
    if (ok) await widget.onCambio();
  }

  Future<void> _abrirDetalle(Reporte r) async {
    final resultado = await showDialog<(EstadoReporte, Prioridad)>(
      context: context,
      builder: (_) => _DetalleReporteDialog(reporte: r),
    );
    if (resultado == null) return;
    final (estado, prioridad) = resultado;
    if (estado == r.estado && prioridad == r.prioridad) return;
    await _actualizar(r, estado: estado, prioridad: prioridad);
  }

  void _limpiarFiltros() => setState(() {
    _estado = null;
    _prioridad = null;
    _colonia = null;
    _busqueda.clear();
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lista = _filtrados;
    final hayFiltros =
        _estado != null ||
        _prioridad != null ||
        _colonia != null ||
        _busqueda.text.isNotEmpty;

    int contar(EstadoReporte? e) => e == null
        ? widget.reportes.length
        : widget.reportes.where((r) => r.estado == e).length;

    return AdminPagina(
      titulo: 'Reportes',
      subtitulo: 'Revisa, prioriza y da seguimiento a cada incidencia',
      icono: Icons.assignment_rounded,
      onRefresh: widget.onCambio,
      children: [
        // Filtros en una sola franja
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _busqueda,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Buscar por descripción, calle, #id…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _busqueda.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () =>
                                      setState(() => _busqueda.clear()),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    _Selector<Prioridad>(
                      icono: Icons.flag_outlined,
                      etiqueta: 'Prioridad',
                      valor: _prioridad,
                      opciones: {
                        for (final p in Prioridad.values) p: p.etiqueta,
                      },
                      onChanged: (v) => setState(() => _prioridad = v),
                    ),
                    _Selector<String>(
                      icono: Icons.map_outlined,
                      etiqueta: 'Colonia',
                      valor: _colonia,
                      opciones: {for (final c in coloniasDisponibles) c: c},
                      onChanged: (v) => setState(() => _colonia = v),
                    ),
                    if (hayFiltros)
                      TextButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Limpiar'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Todos (${contar(null)})'),
                      selected: _estado == null,
                      onSelected: (_) => setState(() => _estado = null),
                    ),
                    for (final e in EstadoReporte.values)
                      ChoiceChip(
                        avatar: Icon(e.icono, size: 16, color: e.color),
                        label: Text('${e.etiqueta} (${contar(e)})'),
                        selected: _estado == e,
                        onSelected: (s) =>
                            setState(() => _estado = s ? e : null),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.cargando && widget.reportes.isEmpty)
          const LoadingList(count: 5)
        else if (widget.error != null)
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar los reportes',
            actionLabel: 'Reintentar',
            onAction: widget.onCambio,
            esError: true,
          )
        else if (lista.isEmpty)
          EstadoMensaje(
            icon: Icons.search_off_rounded,
            titulo: 'Sin resultados',
            detalle: hayFiltros
                ? 'Ningún reporte coincide con los filtros.'
                : 'Aún no hay reportes registrados.',
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final tabla = c.maxWidth >= 760;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    if (tabla) const _EncabezadoTabla(),
                    for (var i = 0; i < lista.length; i++) ...[
                      if (i > 0 || tabla)
                        Divider(height: 1, color: scheme.outlineVariant),
                      tabla
                          ? _FilaTabla(
                              reporte: lista[i],
                              onTap: () => _abrirDetalle(lista[i]),
                              onEstado: (e) => _actualizar(lista[i], estado: e),
                            )
                          : _FilaCompacta(
                              reporte: lista[i],
                              onTap: () => _abrirDetalle(lista[i]),
                            ),
                    ],
                  ],
                ),
              );
            },
          ),
        if (lista.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Mostrando ${lista.length} de ${widget.reportes.length} reportes',
              textAlign: TextAlign.right,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

class _Selector<T> extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final T? valor;
  final Map<T, String> opciones;
  final ValueChanged<T?> onChanged;

  const _Selector({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activo = valor != null;
    return PopupMenuButton<T?>(
      tooltip: 'Filtrar por ${etiqueta.toLowerCase()}',
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text('Cualquier $etiqueta')),
        const PopupMenuDivider(),
        for (final e in opciones.entries)
          PopupMenuItem<T?>(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: activo
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 18),
            const SizedBox(width: 6),
            Text(activo ? opciones[valor]! : etiqueta),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text('ID', style: estilo)),
          Expanded(flex: 4, child: Text('REPORTE', style: estilo)),
          Expanded(flex: 2, child: Text('COLONIA', style: estilo)),
          Expanded(flex: 2, child: Text('FECHA', style: estilo)),
          SizedBox(width: 90, child: Text('PRIORIDAD', style: estilo)),
          SizedBox(width: 150, child: Text('ESTADO', style: estilo)),
        ],
      ),
    );
  }
}

class _FilaTabla extends StatelessWidget {
  final Reporte reporte;
  final VoidCallback onTap;
  final ValueChanged<EstadoReporte> onEstado;

  const _FilaTabla({
    required this.reporte,
    required this.onTap,
    required this.onEstado,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                '#${reporte.id}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  IconoCirculo(
                    icono: reporte.tipo.icono,
                    color: reporte.estado.color,
                    tamano: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${reporte.ubicacion} · ${reporte.ciudadano}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(reporte.colonia)),
            Expanded(flex: 2, child: Text(reporte.fecha)),
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PrioridadChip(prioridad: reporte.prioridad),
              ),
            ),
            SizedBox(
              width: 150,
              child: PopupMenuButton<EstadoReporte>(
                tooltip: 'Cambiar estado',
                onSelected: onEstado,
                itemBuilder: (_) => [
                  for (final e in EstadoReporte.values)
                    PopupMenuItem(
                      value: e,
                      enabled: e != reporte.estado,
                      child: Row(
                        children: [
                          Icon(e.icono, size: 18, color: e.color),
                          const SizedBox(width: 10),
                          Text(e.etiqueta),
                        ],
                      ),
                    ),
                ],
                child: Row(
                  children: [
                    Flexible(
                      child: EstadoChip(estado: reporte.estado, compacto: true),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
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

class _FilaCompacta extends StatelessWidget {
  final Reporte reporte;
  final VoidCallback onTap;

  const _FilaCompacta({required this.reporte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconoCirculo(
              icono: reporte.tipo.icono,
              color: reporte.estado.color,
              tamano: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${reporte.id} · ${reporte.colonia} · ${reporte.fecha}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reporte.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      EstadoChip(estado: reporte.estado, compacto: true),
                      PrioridadChip(prioridad: reporte.prioridad),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DetalleReporteDialog extends StatefulWidget {
  final Reporte reporte;

  const _DetalleReporteDialog({required this.reporte});

  @override
  State<_DetalleReporteDialog> createState() => _DetalleReporteDialogState();
}

class _DetalleReporteDialogState extends State<_DetalleReporteDialog> {
  late EstadoReporte _estado = widget.reporte.estado;
  late Prioridad _prioridad = widget.reporte.prioridad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.reporte;

    Widget dato(IconData icono, String etiqueta, String valor) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icono, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              etiqueta,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          IconoCirculo(icono: r.tipo.icono, color: r.estado.color, tamano: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte #${r.id} · ${r.tipo.etiqueta}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  r.descripcion,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              dato(Icons.location_on_outlined, 'Ubicación', r.ubicacion),
              dato(Icons.map_outlined, 'Colonia', r.colonia),
              dato(Icons.calendar_today_outlined, 'Fecha', r.fecha),
              dato(Icons.person_outline_rounded, 'Ciudadano', r.ciudadano),
              const SizedBox(height: 12),
              SeguimientoReporte(estado: _estado),
              const SizedBox(height: 20),
              const Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in EstadoReporte.values)
                    ChoiceChip(
                      avatar: Icon(e.icono, size: 16, color: e.color),
                      label: Text(e.etiqueta),
                      selected: _estado == e,
                      onSelected: (_) => setState(() => _estado = e),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Prioridad',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<Prioridad>(
                segments: [
                  for (final p in Prioridad.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.etiqueta),
                      icon: Icon(Icons.flag_rounded, color: p.color),
                    ),
                ],
                selected: {_prioridad},
                onSelectionChanged: (s) => setState(() => _prioridad = s.first),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, (_estado, _prioridad)),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}
