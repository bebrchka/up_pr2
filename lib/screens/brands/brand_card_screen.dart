import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../state/brand_details_notifier.dart';
import '../../state/load_status.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_views.dart';

class BrandCardScreen extends StatelessWidget {
  const BrandCardScreen({super.key, required this.brandId});

  final int brandId;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandDetailsNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Бренд #$brandId'),
        actions: [
          IconButton(
            tooltip: 'К списку брендов',
            icon: const Icon(Icons.list_alt),
            onPressed: () => goBackOr(context, '/brands'),
          ),
          IconButton(
            tooltip: 'На главную',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: _body(context, notifier),
    );
  }

  Widget _body(BuildContext context, BrandDetailsNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        final brand = notifier.brand;
        if (brand == null) {
          return const EmptyView(
            title: 'Бренд не найден',
            message: 'Возможно, запись удалена навсегда.',
          );
        }
        return _details(context, notifier, brand);
    }
  }

  Widget _details(
    BuildContext context,
    BrandDetailsNotifier notifier,
    Brand brand,
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          brand.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (brand.isDeleted)
                        Chip(
                          label: const Text('Удалён'),
                          backgroundColor: theme.colorScheme.errorContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Страна', value: brand.country),
                  _InfoRow(label: 'Город', value: brand.city),
                  _InfoRow(
                    label: 'Год основания',
                    value: '${brand.foundedYear}',
                  ),
                  _InfoRow(label: 'Сайт', value: brand.website),
                  _InfoRow(label: 'Описание', value: brand.description),
                  if (brand.deletedAt != null)
                    _InfoRow(
                      label: 'Дата удаления',
                      value: formatDate(brand.deletedAt!),
                    ),
                  const Divider(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => goBackOr(context, '/brands'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('К списку'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.go('/items'),
                        icon: const Icon(Icons.checkroom),
                        label: const Text('Каталог одежды'),
                      ),
                      if (brand.isDeleted)
                        FilledButton.icon(
                          onPressed: () => notifier.restore(),
                          icon: const Icon(Icons.restore),
                          label: const Text('Восстановить'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => notifier.softDelete(),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Логически удалить'),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => _hardDelete(context, notifier, brand),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Удалить навсегда'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _hardDelete(
    BuildContext context,
    BrandDetailsNotifier notifier,
    Brand brand,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить бренд навсегда?',
      message:
          '«${brand.name}» будет стёрт из памяти без возможности '
          'восстановления.',
    );
    if (!confirmed || !context.mounted) return;
    await notifier.hardDelete();
    if (!context.mounted) return;
    context.go('/brands');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
