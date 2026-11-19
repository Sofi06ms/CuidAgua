import 'package:flutter/material.dart';

/// Encabezado de sección con acción opcional ("Ver todos").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Tarjetas grises que simulan contenido mientras carga.
class LoadingList extends StatelessWidget {
  final int count;

  const LoadingList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Column(
      children: List.generate(count, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(double.infinity, 14),
                        const SizedBox(height: 8),
                        bar(120, 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Mensaje amigable para listas vacías o errores, con acción opcional.
class EstadoMensaje extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? detalle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool esError;

  const EstadoMensaje({
    super.key,
    required this.icon,
    required this.titulo,
    this.detalle,
    this.actionLabel,
    this.onAction,
    this.esError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = esError ? scheme.error : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: tint.withValues(alpha: 0.12),
              child: Icon(icon, color: tint, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(esError ? Icons.refresh : Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
