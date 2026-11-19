import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/comunes.dart';
import '../../widgets/estado_widgets.dart';
import 'admin_shell.dart';

/// Publicación y eliminación de avisos de suministro.
class AdminAvisos extends StatelessWidget {
  final ApiService api;
  final List<AvisoSuministro> avisos;
  final bool cargando;
  final Object? error;
  final Future<void> Function() onCambio;

  const AdminAvisos({
    super.key,
    required this.api,
    required this.avisos,
    required this.cargando,
    required this.error,
    required this.onCambio,
  });

  Future<void> _nuevo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final aviso = await showDialog<AvisoSuministro>(
      context: context,
      builder: (_) => const _NuevoAvisoDialog(),
    );
    if (aviso == null) return;
    final ok = await api.crearAviso(aviso);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Aviso publicado para la colonia ${aviso.coloniaAfectada}'
              : 'No se pudo publicar el aviso',
        ),
      ),
    );
    if (ok) await onCambio();
  }

  Future<void> _eliminar(BuildContext context, AvisoSuministro a) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('¿Eliminar aviso?'),
        content: Text(
          '“${a.titulo}” dejará de mostrarse a los ciudadanos de '
          '${a.coloniaAfectada}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final ok = await api.eliminarAviso(a.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Aviso eliminado' : 'No se pudo eliminar el aviso'),
      ),
    );
    if (ok) await onCambio();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPagina(
      titulo: 'Avisos de suministro',
      subtitulo: 'Informa a la ciudadanía sobre cortes y horarios',
      icono: Icons.campaign_rounded,
      color: AppTheme.naranja,
      onRefresh: onCambio,
      acciones: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: const StadiumBorder(),
          ),
          onPressed: () => _nuevo(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo aviso'),
        ),
      ],
      children: [
        if (cargando && avisos.isEmpty)
          const LoadingList()
        else if (error != null)
          EstadoMensaje(
            icon: Icons.cloud_off_rounded,
            titulo: 'No pudimos cargar los avisos',
            actionLabel: 'Reintentar',
            onAction: onCambio,
            esError: true,
          )
        else if (avisos.isEmpty)
          EstadoMensaje(
            icon: Icons.campaign_outlined,
            titulo: 'No hay avisos publicados',
            detalle:
                'Publica un aviso para informar sobre cortes o '
                'mantenimientos.',
            actionLabel: 'Nuevo aviso',
            onAction: () => _nuevo(context),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 1100 ? 2 : 1;
              const gap = 12.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in avisos)
                    SizedBox(
                      width: w,
                      child: AvisoCard(
                        aviso: a,
                        onEliminar: () => _eliminar(context, a),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _NuevoAvisoDialog extends StatefulWidget {
  const _NuevoAvisoDialog();

  @override
  State<_NuevoAvisoDialog> createState() => _NuevoAvisoDialogState();
}

class _NuevoAvisoDialogState extends State<_NuevoAvisoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _detalle = TextEditingController();
  final _horario = TextEditingController();
  TipoAviso _tipo = TipoAviso.corte;
  String _colonia = coloniasDisponibles.first;

  @override
  void dispose() {
    _titulo.dispose();
    _detalle.dispose();
    _horario.dispose();
    super.dispose();
  }

  void _publicar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AvisoSuministro(
        id: 0,
        titulo: _titulo.text.trim(),
        detalle: _detalle.text.trim(),
        coloniaAfectada: _colonia,
        tipo: _tipo,
        horario: _horario.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? requerido(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

    return AlertDialog(
      title: const Text('Nuevo aviso'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de aviso',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TipoAviso.values)
                      ChoiceChip(
                        avatar: Icon(
                          AvisoCard.iconoDe(t),
                          size: 16,
                          color: AvisoCard.colorDe(t),
                        ),
                        label: Text(t.etiqueta),
                        selected: _tipo == t,
                        onSelected: (_) => setState(() {
                          _tipo = t;
                          if (_titulo.text.isEmpty ||
                              TipoAviso.values.any(
                                (x) => x.etiqueta == _titulo.text,
                              )) {
                            _titulo.text = t.etiqueta;
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titulo,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: requerido,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detalle,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Detalle',
                    hintText: 'Ej. Sustitución de válvula en la red principal',
                  ),
                  validator: requerido,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _colonia,
                  decoration: const InputDecoration(
                    labelText: 'Colonia afectada',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: [
                    for (final c in coloniasDisponibles)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _colonia = v ?? _colonia),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _horario,
                  decoration: const InputDecoration(
                    labelText: 'Horario',
                    hintText: 'Ej. Jue 20 nov · 08:00 – 14:00',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  validator: requerido,
                ),
              ],
            ),
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
          onPressed: _publicar,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Publicar'),
        ),
      ],
    );
  }
}
