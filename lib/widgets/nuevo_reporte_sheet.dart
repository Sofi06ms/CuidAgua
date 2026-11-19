import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Hoja inferior con el formulario para enviar un reporte ciudadano.
/// Devuelve `true` al cerrarse si el reporte se envió correctamente.
class NuevoReporteSheet extends StatefulWidget {
  final ApiService apiService;
  final Usuario usuario;
  final TipoProblema? tipoInicial;

  const NuevoReporteSheet({
    super.key,
    required this.apiService,
    required this.usuario,
    this.tipoInicial,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required ApiService api,
    required Usuario usuario,
    TipoProblema? tipoInicial,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => NuevoReporteSheet(
        apiService: api,
        usuario: usuario,
        tipoInicial: tipoInicial,
      ),
    );
  }

  @override
  State<NuevoReporteSheet> createState() => _NuevoReporteSheetState();
}

class _NuevoReporteSheetState extends State<NuevoReporteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  TipoProblema? _tipo;
  late String _colonia;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
    _colonia = coloniasDisponibles.contains(widget.usuario.colonia)
        ? widget.usuario.colonia
        : coloniasDisponibles.first;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _enviando) return;

    setState(() => _enviando = true);
    final messenger = ScaffoldMessenger.of(context);
    final texto = _descripcionController.text.trim();

    try {
      final exito = await widget.apiService.enviarReporte(
        texto.isEmpty ? _tipo!.etiqueta : texto,
        _ubicacionController.text.trim(),
        tipo: _tipo ?? TipoProblema.otro,
        colonia: _colonia,
        ciudadano: widget.usuario.nombre,
      );
      if (!mounted) return;

      if (exito) {
        Navigator.of(context).pop(true);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No pudimos enviar tu reporte. Intenta de nuevo.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo reporte',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cuéntanos qué pasa y dónde. Tu reporte ayuda a toda la colonia.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              const _Paso(numero: 1, texto: '¿Qué tipo de problema es?'),
              const SizedBox(height: 12),
              FormField<TipoProblema>(
                initialValue: _tipo,
                validator: (_) =>
                    _tipo == null ? 'Selecciona un tipo de problema' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.25,
                      children: TipoProblema.values.map((t) {
                        final sel = _tipo == t;
                        return Material(
                          color: sel
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest.withValues(
                                  alpha: 0.6,
                                ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: sel ? scheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() => _tipo = t);
                              field.didChange(t);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  t.icono,
                                  color: sel
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.etiqueta,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const _Paso(numero: 2, texto: 'Describe el problema (opcional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                minLines: 2,
                maxLines: 4,
                maxLength: 250,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Ej. Hay una fuga frente a la tienda desde la mañana',
                ),
              ),
              const SizedBox(height: 10),

              const _Paso(numero: 3, texto: '¿Dónde está?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _colonia,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined),
                  labelText: 'Colonia',
                ),
                items: coloniasDisponibles
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _colonia = v ?? _colonia),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ubicacionController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  labelText: 'Calle y número o referencia',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Indica la ubicación del problema'
                    : null,
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_enviando ? 'Enviando…' : 'Enviar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final int numero;
  final String texto;

  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: scheme.primary,
          child: Text(
            '$numero',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
