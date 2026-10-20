import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/brand_query.dart';
import 'models/item_query.dart';
import 'repositories/brand_repository.dart';
import 'repositories/item_repository.dart';
import 'screens/brands/brand_card_screen.dart';
import 'screens/brands/brand_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/items/item_card_screen.dart';
import 'screens/items/item_list_screen.dart';
import 'state/brand_details_notifier.dart';
import 'state/item_details_notifier.dart';

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/items',
        builder: (context, state) => ItemListScreen(
          query: ItemQuery.fromQueryParameters(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChangeNotifierProvider<ItemDetailsNotifier>(
            create: (context) =>
                ItemDetailsNotifier(context.read<ItemRepository>(), id)..load(),
            child: ItemCardScreen(itemId: id),
          );
        },
      ),
      GoRoute(
        path: '/brands',
        builder: (context, state) => BrandListScreen(
          query: BrandQuery.fromQueryParameters(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/brands/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChangeNotifierProvider<BrandDetailsNotifier>(
            create: (context) =>
                BrandDetailsNotifier(context.read<BrandRepository>(), id)
                  ..load(),
            child: BrandCardScreen(brandId: id),
          );
        },
      ),
    ],
  );
}
