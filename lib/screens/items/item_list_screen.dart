import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/seed_data.dart';
import '../../models/clothing_item.dart';
import '../../models/item_query.dart';
import '../../state/item_list_notifier.dart';
import '../../state/load_status.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/debounced_text_field.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/responsive_entity_view.dart';
import '../../widgets/status_views.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key, required this.query});

  final ItemQuery query;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromUrl());
  }

  @override
  void didUpdateWidget(covariant ItemListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromUrl());
    }
  }

  void _syncFromUrl() {
    if (!mounted) return;
    final notifier = context.read<ItemListNotifier>();
    if (widget.query != notifier.query || notifier.status == LoadStatus.idle) {
      notifier.applyQuery(widget.query);
    }
  }

  ItemQuery get _currentQuery => context.read<ItemListNotifier>().query;

  void _apply(ItemQuery next) {
    if (next == widget.query) return;
    context.go(next.toLocation());
  }

  void _sort(String field) {
    final query = _currentQuery;
    final ascending = field == query.sortField ? !query.sortAscending : true;
    _apply(query.copyWith(sortField: field, sortAscending: ascending));
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<ItemListNotifier>();
    final count = notifier.selected.length;
    if (count == 0) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить выбранные товары?',
      message:
          'Будет помечено как удалённое: $count. Записи можно восстановить, '
          'включив показ удалённых.',
    );
    if (!confirmed || !mounted) return;
    await notifier.deleteSelected();
  }

  Future<void> _hardDelete(ClothingItem item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить навсегда?',
      message:
          'Товар «${item.title}» будет стёрт из памяти без возможности '
          'восстановления.',
    );
    if (!confirmed || !mounted) return;
    await context.read<ItemListNotifier>().hardDelete(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ItemListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог одежды'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            tooltip: notifier.forceError
                ? 'Выключить режим ошибки'
                : 'Демонстрация ошибки загрузки',
            icon: Icon(
              notifier.forceError
                  ? Icons.bug_report
                  : Icons.bug_report_outlined,
            ),
            onPressed: () => notifier.setForceError(!notifier.forceError),
          ),
        ],
      ),
      body: Column(
        children: [
          _filters(context, notifier),
          if (notifier.hasSelection) _selectionBar(context, notifier),
          Expanded(child: _body(context, notifier)),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.query.size,
            total: notifier.result.total,
            onPageChanged: (page) => _apply(_currentQuery.copyWith(page: page)),
            onSizeChanged: (size) => _apply(_currentQuery.copyWith(size: size)),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context, ItemListNotifier notifier) {
    final query = notifier.query;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DebouncedTextField(
              value: query.search,
              label: 'Поиск: название или артикул',
              width: 260,
              onChanged: (value) =>
                  _apply(_currentQuery.copyWith(search: value)),
            ),
            SizedBox(
              width: 190,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    isDense: true,
                    value:
                        seedCategories.any(
                          (category) => category.id == query.categoryId,
                        )
                        ? query.categoryId
                        : null,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Все категории'),
                      ),
                      for (final category in seedCategories)
                        DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) =>
                        _apply(_currentQuery.copyWith(categoryId: value)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Бренд',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    isDense: true,
                    value: seedBrands.any((brand) => brand.id == query.brandId)
                        ? query.brandId
                        : null,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Все бренды'),
                      ),
                      for (final brand in seedBrands)
                        DropdownMenuItem<int>(
                          value: brand.id,
                          child: Text(brand.name),
                        ),
                    ],
                    onChanged: (value) =>
                        _apply(_currentQuery.copyWith(brandId: value)),
                  ),
                ),
              ),
            ),
            DebouncedTextField(
              value: query.priceFrom?.toString() ?? '',
              label: 'Цена от',
              width: 130,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_outlined,
              onChanged: (value) => _apply(
                _currentQuery.copyWith(priceFrom: int.tryParse(value)),
              ),
            ),
            DebouncedTextField(
              value: query.priceTo?.toString() ?? '',
              label: 'Цена до',
              width: 130,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_outlined,
              onChanged: (value) =>
                  _apply(_currentQuery.copyWith(priceTo: int.tryParse(value))),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Показывать удалённые'),
                Switch(
                  value: query.includeDeleted,
                  onChanged: (value) =>
                      _apply(_currentQuery.copyWith(includeDeleted: value)),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => _apply(ItemQuery(size: _currentQuery.size)),
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionBar(BuildContext context, ItemListNotifier notifier) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Выбрано: ${notifier.selected.length}',
              style: theme.textTheme.titleSmall,
            ),
            TextButton(
              onPressed: notifier.clearSelection,
              child: const Text('Снять выделение'),
            ),
            FilledButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Удалить выбранные'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ItemListNotifier notifier) {
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
        if (notifier.result.items.isEmpty) {
          return const EmptyView();
        }
        return ResponsiveEntityView<ClothingItem>(
          items: notifier.result.items,
          cardBuilder: (context, item) => _card(context, notifier, item),
          tableBuilder: (context) => _table(context, notifier),
        );
    }
  }

  Widget _table(BuildContext context, ItemListNotifier notifier) {
    return EntityTable<ClothingItem>(
      items: notifier.result.items,
      idOf: (item) => item.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: _sort,
      isDeleted: (item) => item.isDeleted,
      columns: [
        TableColumnSpec<ClothingItem>(
          label: 'Название',
          sortField: 'title',
          build: (item) => Text(item.title),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'Артикул',
          build: (item) => Text(item.sku),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'Бренд',
          build: (item) => Text(brandNameOf(item.brandId)),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'Категории',
          build: (item) => Text(categoryNamesOf(item.categoryIds)),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'Год',
          sortField: 'year',
          numeric: true,
          build: (item) => Text('${item.year}'),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'Цена, ₽',
          sortField: 'price',
          numeric: true,
          build: (item) => Text('${item.price}'),
        ),
        TableColumnSpec<ClothingItem>(
          label: 'В наличии',
          numeric: true,
          build: (item) => Text('${item.stockAvailable}/${item.stockTotal}'),
        ),
      ],
      actions: (item) => _rowActions(context, notifier, item),
    );
  }

  List<Widget> _rowActions(
    BuildContext context,
    ItemListNotifier notifier,
    ClothingItem item,
  ) {
    return [
      IconButton(
        tooltip: 'Открыть карточку',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.push('/items/${item.id}'),
      ),
      if (item.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => notifier.restore(item.id),
        )
      else
        IconButton(
          tooltip: 'Логическое удаление',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => notifier.softDelete(item.id),
        ),
      IconButton(
        tooltip: 'Удалить навсегда',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete_forever, size: 20),
        onPressed: () => _hardDelete(item),
      ),
    ];
  }

  Widget _card(
    BuildContext context,
    ItemListNotifier notifier,
    ClothingItem item,
  ) {
    final theme = Theme.of(context);
    final selected = notifier.selected.contains(item.id);
    return Card(
      color: item.isDeleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/items/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => notifier.toggleSelection(item.id),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${brandNameOf(item.brandId)} • '
                      '${categoryNamesOf(item.categoryIds)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${item.sku} • ${item.year} г. • ${item.price} ₽',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'В наличии: ${item.stockAvailable} из ${item.stockTotal}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.isDeleted)
                      Text(
                        'Удалён',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Действия',
                onSelected: (action) {
                  switch (action) {
                    case 'open':
                      context.push('/items/${item.id}');
                    case 'soft':
                      notifier.softDelete(item.id);
                    case 'restore':
                      notifier.restore(item.id);
                    case 'hard':
                      _hardDelete(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'open',
                    child: Text('Открыть карточку'),
                  ),
                  if (item.isDeleted)
                    const PopupMenuItem<String>(
                      value: 'restore',
                      child: Text('Восстановить'),
                    )
                  else
                    const PopupMenuItem<String>(
                      value: 'soft',
                      child: Text('Логически удалить'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'hard',
                    child: Text('Удалить навсегда'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
