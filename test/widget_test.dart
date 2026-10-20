import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pr_up/repositories/brand_repository.dart';
import 'package:pr_up/repositories/in_memory_brand_repository.dart';
import 'package:pr_up/repositories/in_memory_item_repository.dart';
import 'package:pr_up/repositories/item_repository.dart';
import 'package:pr_up/router.dart';
import 'package:pr_up/state/brand_list_notifier.dart';
import 'package:pr_up/state/item_list_notifier.dart';
import 'package:provider/provider.dart';

Widget buildTestApp({String location = '/'}) {
  return MultiProvider(
    providers: [
      Provider<ItemRepository>(create: (_) => InMemoryItemRepository()),
      Provider<BrandRepository>(create: (_) => InMemoryBrandRepository()),
      ChangeNotifierProvider<ItemListNotifier>(
        create: (context) => ItemListNotifier(context.read<ItemRepository>()),
      ),
      ChangeNotifierProvider<BrandListNotifier>(
        create: (context) => BrandListNotifier(context.read<BrandRepository>()),
      ),
      Provider<GoRouter>(create: (_) => buildRouter(initialLocation: location)),
    ],
    child: Builder(
      builder: (context) => MaterialApp.router(
        theme: ThemeData(useMaterial3: true),
        routerConfig: context.read<GoRouter>(),
      ),
    ),
  );
}

void main() {
  testWidgets('каталог: таблица, карточка товара и возврат', (tester) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(location: '/items?size=25'));
    await tester.pumpAndSettle();

    expect(find.text('Название'), findsOneWidget);
    expect(find.text('Футболка «Базовая»'), findsOneWidget);

    await tester.tap(find.byTooltip('Открыть карточку').first);
    await tester.pumpAndSettle();
    expect(find.text('Артикул'), findsOneWidget);
    expect(find.text('К списку'), findsOneWidget);

    await tester.tap(find.text('К списку'));
    await tester.pumpAndSettle();
    expect(find.text('Название'), findsOneWidget);
  });

  testWidgets('параметры адреса восстанавливают поиск', (tester) async {
    await tester.pumpWidget(
      buildTestApp(location: '/items?search=джинсы&sort=price,desc&size=25'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Джинсы Slim Fit'), findsOneWidget);
    expect(find.text('Джинсы Wide Leg'), findsOneWidget);
    expect(find.text('Футболка «Базовая»'), findsNothing);
    expect(find.textContaining('Всего записей: 2'), findsOneWidget);
  });

  testWidgets('на узком окне таблица заменяется карточками', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(location: '/items?size=25'));
    await tester.pumpAndSettle();

    expect(find.textContaining('В наличии:'), findsWidgets);
    expect(find.text('Артикул'), findsNothing);
  });

  testWidgets('пустой результат отличается от загрузки', (tester) async {
    await tester.pumpWidget(
      buildTestApp(location: '/items?search=несуществующий-товар-123'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
