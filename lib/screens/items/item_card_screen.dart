import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/seed_data.dart';
import '../../models/clothing_item.dart';
import '../../state/item_details_notifier.dart';
import '../../state/load_status.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_views.dart';

class ItemCardScreen extends StatelessWidget {
  const ItemCardScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ItemDetailsNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Товар #$itemId'),
        actions: [
          IconButton(
            tooltip: 'К списку товаров',
            icon: const Icon(Icons.list_alt),
            onPressed: () => goBackOr(context, '/items'),
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

  Widget _body(BuildContext context, ItemDetailsNotifier notifier) {
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
        final item = notifier.item;
        if (item == null) {
          return const EmptyView(
            title: 'Товар не найден',
            message: 'Возможно, запись удалена навсегда.',
          );
        }
        return _details(context, notifier, item);
    }
  }

  Widget _details(
    BuildContext context,
    ItemDetailsNotifier notifier,
    ClothingItem item,
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
                          item.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (item.isDeleted)
                        Chip(
                          label: const Text('Удалён'),
                          backgroundColor: theme.colorScheme.errorContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Артикул', value: item.sku),
                  _InfoRow(label: 'Бренд', value: brandNameOf(item.brandId)),
                  _InfoRow(
                    label: 'Категории',
                    value: categoryNamesOf(item.categoryIds),
                  ),
                  _InfoRow(label: 'Год коллекции', value: '${item.year}'),
                  _InfoRow(label: 'Цена', value: '${item.price} ₽'),
                  _InfoRow(
                    label: 'На складе',
                    value: '${item.stockAvailable} из ${item.stockTotal}',
                  ),
                  if (item.deletedAt != null)
                    _InfoRow(
                      label: 'Дата удаления',
                      value: formatDate(item.deletedAt!),
                    ),
                  const Divider(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => goBackOr(context, '/items'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('К списку'),
                      ),
                      if (item.isDeleted)
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
                        onPressed: () => _hardDelete(context, notifier, item),
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
    ItemDetailsNotifier notifier,
    ClothingItem item,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить товар навсегда?',
      message:
          '«${item.title}» будет удалён из памяти без возможности '
          'восстановления.',
    );
    if (!confirmed || !context.mounted) return;
    await notifier.hardDelete();
    if (!context.mounted) return;
    context.go('/items');
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
