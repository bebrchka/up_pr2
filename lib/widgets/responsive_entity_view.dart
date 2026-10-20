import 'package:flutter/material.dart';

class ResponsiveEntityView<T> extends StatelessWidget {
  const ResponsiveEntityView({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.tableBuilder,
  });

  static const double breakpoint = 600;

  final List<T> items;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final WidgetBuilder tableBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => cardBuilder(context, items[index]),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: tableBuilder(context),
        );
      },
    );
  }
}
