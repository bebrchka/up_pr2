import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.size,
    required this.total,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  static const List<int> pageSizes = [10, 25, 50];

  final int page;
  final int size;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = total == 0 ? 1 : (total / size).ceil();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('Всего записей: $total'),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('На странице:'),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: size,
                    items: [
                      for (final value in pageSizes)
                        DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != size) {
                        onSizeChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Первая страница',
              icon: const Icon(Icons.first_page),
              onPressed: page > 1 ? () => onPageChanged(1) : null,
            ),
            IconButton(
              tooltip: 'Предыдущая страница',
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            ),
            Text(
              'Страница $page из $totalPages',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            IconButton(
              tooltip: 'Следующая страница',
              icon: const Icon(Icons.chevron_right),
              onPressed: page < totalPages
                  ? () => onPageChanged(page + 1)
                  : null,
            ),
            IconButton(
              tooltip: 'Последняя страница',
              icon: const Icon(Icons.last_page),
              onPressed: page < totalPages
                  ? () => onPageChanged(totalPages)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
