import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'repositories/brand_repository.dart';
import 'repositories/in_memory_brand_repository.dart';
import 'repositories/in_memory_item_repository.dart';
import 'repositories/item_repository.dart';
import 'router.dart';
import 'state/brand_list_notifier.dart';
import 'state/item_list_notifier.dart';

void main() {
  // Чистые адреса без # — условия отбора сохраняются в строке запроса.
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<ItemRepository>(create: (_) => InMemoryItemRepository()),
        Provider<BrandRepository>(create: (_) => InMemoryBrandRepository()),
        ChangeNotifierProvider<ItemListNotifier>(
          create: (context) => ItemListNotifier(context.read<ItemRepository>()),
        ),
        ChangeNotifierProvider<BrandListNotifier>(
          create: (context) =>
              BrandListNotifier(context.read<BrandRepository>()),
        ),
        Provider<GoRouter>(create: (_) => buildRouter()),
      ],
      child: const ClothingStoreApp(),
    ),
  );
}

class ClothingStoreApp extends StatelessWidget {
  const ClothingStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Магазин одежды',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      routerConfig: context.read<GoRouter>(),
    );
  }
}
