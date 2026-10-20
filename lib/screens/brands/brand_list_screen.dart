import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/seed_data.dart';
import '../../models/brand.dart';
import '../../models/brand_query.dart';
import '../../state/brand_list_notifier.dart';
import '../../state/load_status.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/debounced_text_field.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/responsive_entity_view.dart';
import '../../widgets/status_views.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key, required this.query});

  final BrandQuery query;

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  late final List<String> _countries = brandCountries();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromUrl());
  }

  @override
  void didUpdateWidget(covariant BrandListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromUrl());
    }
  }

  void _syncFromUrl() {
    if (!mounted) return;
    final notifier = context.read<BrandListNotifier>();
    if (widget.query != notifier.query || notifier.status == LoadStatus.idle) {
      notifier.applyQuery(widget.query);
    }
  }

  BrandQuery get _currentQuery => context.read<BrandListNotifier>().query;

  void _apply(BrandQuery next) {
    if (next == widget.query) return;
    context.go(next.toLocation());
  }

  void _sort(String field) {
    final query = _currentQuery;
    final ascending = field == query.sortField ? !query.sortAscending : true;
    _apply(query.copyWith(sortField: field, sortAscending: ascending));
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<BrandListNotifier>();
    final count = notifier.selected.length;
    if (count == 0) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить выбранные бренды?',
      message: 'Будет помечено как удалённое: $count.',
    );
    if (!confirmed || !mounted) return;
    await notifier.deleteSelected();
  }

  Future<void> _hardDelete(Brand brand) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить навсегда?',
      message:
          'Бренд «${brand.name}» будет стёрт из памяти без возможности '
          'восстановления.',
    );
    if (!confirmed || !mounted) return;
    await context.read<BrandListNotifier>().hardDelete(brand.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бренды'),
        actions: [
          IconButton(
            tooltip: 'Каталог одежды',
            icon: const Icon(Icons.checkroom),
            onPressed: () => context.go('/items'),
          ),
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

  Widget _filters(BuildContext context, BrandListNotifier notifier) {
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
              label: 'Поиск: название или страна',
              width: 260,
              onChanged: (value) =>
                  _apply(_currentQuery.copyWith(search: value)),
            ),
            SizedBox(
              width: 190,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Страна',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: _countries.contains(query.country)
                        ? query.country
                        : null,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Все страны'),
                      ),
                      for (final country in _countries)
                        DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        ),
                    ],
                    onChanged: (value) =>
                        _apply(_currentQuery.copyWith(country: value)),
                  ),
                ),
              ),
            ),
            DebouncedTextField(
              value: query.yearFrom?.toString() ?? '',
              label: 'Основан с',
              width: 130,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.calendar_today_outlined,
              onChanged: (value) =>
                  _apply(_currentQuery.copyWith(yearFrom: int.tryParse(value))),
            ),
            DebouncedTextField(
              value: query.yearTo?.toString() ?? '',
              label: 'Основан по',
              width: 130,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.calendar_today_outlined,
              onChanged: (value) =>
                  _apply(_currentQuery.copyWith(yearTo: int.tryParse(value))),
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
              onPressed: () => _apply(BrandQuery(size: _currentQuery.size)),
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionBar(BuildContext context, BrandListNotifier notifier) {
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

  Widget _body(BuildContext context, BrandListNotifier notifier) {
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
        return ResponsiveEntityView<Brand>(
          items: notifier.result.items,
          cardBuilder: (context, brand) => _card(context, notifier, brand),
          tableBuilder: (context) => _table(context, notifier),
        );
    }
  }

  Widget _table(BuildContext context, BrandListNotifier notifier) {
    return EntityTable<Brand>(
      items: notifier.result.items,
      idOf: (brand) => brand.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: _sort,
      isDeleted: (brand) => brand.isDeleted,
      columns: [
        TableColumnSpec<Brand>(
          label: 'Название',
          sortField: 'name',
          build: (brand) => Text(brand.name),
        ),
        TableColumnSpec<Brand>(
          label: 'Страна',
          sortField: 'country',
          build: (brand) => Text(brand.country),
        ),
        TableColumnSpec<Brand>(
          label: 'Город',
          build: (brand) => Text(brand.city),
        ),
        TableColumnSpec<Brand>(
          label: 'Основан',
          sortField: 'foundedYear',
          numeric: true,
          build: (brand) => Text('${brand.foundedYear}'),
        ),
        TableColumnSpec<Brand>(
          label: 'Сайт',
          build: (brand) => Text(brand.website),
        ),
      ],
      actions: (brand) => _rowActions(context, notifier, brand),
    );
  }

  List<Widget> _rowActions(
    BuildContext context,
    BrandListNotifier notifier,
    Brand brand,
  ) {
    return [
      IconButton(
        tooltip: 'Открыть карточку',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.open_in_new, size: 20),
        onPressed: () => context.push('/brands/${brand.id}'),
      ),
      if (brand.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.restore, size: 20),
          onPressed: () => notifier.restore(brand.id),
        )
      else
        IconButton(
          tooltip: 'Логическое удаление',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => notifier.softDelete(brand.id),
        ),
      IconButton(
        tooltip: 'Удалить навсегда',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete_forever, size: 20),
        onPressed: () => _hardDelete(brand),
      ),
    ];
  }

  Widget _card(BuildContext context, BrandListNotifier notifier, Brand brand) {
    final theme = Theme.of(context);
    final selected = notifier.selected.contains(brand.id);
    return Card(
      color: brand.isDeleted
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/brands/${brand.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => notifier.toggleSelection(brand.id),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brand.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${brand.country}, ${brand.city} • основан в '
                      '${brand.foundedYear}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(brand.website, style: theme.textTheme.bodySmall),
                    Text(brand.description, style: theme.textTheme.bodySmall),
                    if (brand.isDeleted)
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
                      context.push('/brands/${brand.id}');
                    case 'soft':
                      notifier.softDelete(brand.id);
                    case 'restore':
                      notifier.restore(brand.id);
                    case 'hard':
                      _hardDelete(brand);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'open',
                    child: Text('Открыть карточку'),
                  ),
                  if (brand.isDeleted)
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
