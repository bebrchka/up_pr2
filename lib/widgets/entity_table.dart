import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const <int>{},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSelection = onToggleSelect != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: showSelection,
        headingRowColor: WidgetStatePropertyAll<Color?>(
          theme.colorScheme.surfaceContainerHighest,
        ),
        columnSpacing: 24,
        horizontalMargin: 16,
        columns: [
          for (final column in columns)
            DataColumn(
              numeric: column.numeric,
              label: _SortableHeader<T>(
                column: column,
                active:
                    column.sortField != null && column.sortField == sortField,
                ascending: sortAscending,
                onSort: onSort,
              ),
            ),
          if (actions != null) const DataColumn(label: Text('Действия')),
        ],
        rows: [
          for (final item in items)
            DataRow(
              selected: selected.contains(idOf(item)),
              onSelectChanged: showSelection
                  ? (_) => onToggleSelect!(idOf(item))
                  : null,
              color: (isDeleted?.call(item) ?? false)
                  ? WidgetStatePropertyAll<Color?>(
                      theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    )
                  : null,
              cells: [
                for (final column in columns) DataCell(column.build(item)),
                if (actions != null)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!(item),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SortableHeader<T> extends StatelessWidget {
  const _SortableHeader({
    required this.column,
    required this.active,
    required this.ascending,
    required this.onSort,
  });

  final TableColumnSpec<T> column;
  final bool active;
  final bool ascending;
  final void Function(String field)? onSort;

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(column.label),
        if (column.sortField != null) ...[
          const SizedBox(width: 4),
          Icon(
            !active
                ? Icons.unfold_more
                : (ascending ? Icons.arrow_upward : Icons.arrow_downward),
            size: 16,
          ),
        ],
      ],
    );
    final field = column.sortField;
    if (field == null || onSort == null) return label;
    return InkWell(
      onTap: () => onSort!(field),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: label,
      ),
    );
  }
}
