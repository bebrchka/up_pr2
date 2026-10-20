import 'package:flutter_test/flutter_test.dart';
import 'package:pr_up/data/seed_data.dart';
import 'package:pr_up/models/brand_query.dart';
import 'package:pr_up/models/clothing_item.dart';
import 'package:pr_up/models/item_query.dart';
import 'package:pr_up/repositories/in_memory_brand_repository.dart';
import 'package:pr_up/repositories/in_memory_item_repository.dart';

ClothingItem testItem(
  int id, {
  String title = 'Тестовый товар',
  String sku = 'TEST',
  int price = 1000,
  int year = 2024,
  int brandId = 1,
  List<int> categoryIds = const [1],
}) {
  return ClothingItem(
    id: id,
    title: title,
    sku: sku,
    price: price,
    year: year,
    brandId: brandId,
    categoryIds: categoryIds,
    stockTotal: 10,
    stockAvailable: 5,
  );
}

void main() {
  group('Начальные данные', () {
    test('не менее 20 товаров и 8 брендов', () {
      expect(seedItems.length, greaterThanOrEqualTo(20));
      expect(seedBrands.length, greaterThanOrEqualTo(8));
    });
  });

  group('InMemoryItemRepository', () {
    test('постраничный вывод: 10 записей на странице', () async {
      final repository = InMemoryItemRepository();
      final first = await repository.find(const ItemQuery());
      expect(first.items.length, 10);
      expect(first.total, 24);
      expect(first.totalPages, 3);
      expect(first.hasPrevious, isFalse);
      expect(first.hasNext, isTrue);

      final last = await repository.find(const ItemQuery(page: 3));
      expect(last.items.length, 4);
      expect(last.hasNext, isFalse);
    });

    test('поиск по названию и артикулу', () async {
      final repository = InMemoryItemRepository();

      final byTitle = await repository.find(
        const ItemQuery(search: 'джинсы', size: 50),
      );
      expect(byTitle.total, 2);

      final bySku = await repository.find(const ItemQuery(search: 'TS-1001'));
      expect(bySku.total, 1);
      expect(bySku.items.single.title, 'Футболка «Базовая»');
    });

    test('категория, бренд, цена и поиск комбинируются', () async {
      final repository = InMemoryItemRepository();
      final result = await repository.find(
        const ItemQuery(
          search: 'карго',
          categoryId: 7,
          brandId: 7,
          priceFrom: 4000,
          priceTo: 5000,
        ),
      );
      expect(result.total, 1);
      expect(result.items.single.sku, 'PN-9004');
    });

    test('логическое удаление скрывает запись, restore возвращает', () async {
      final repository = InMemoryItemRepository(
        items: [testItem(1), testItem(2), testItem(3)],
      );

      await repository.softDelete(2);
      var visible = await repository.find(const ItemQuery());
      expect(visible.total, 2);
      expect(visible.items.any((item) => item.id == 2), isFalse);

      final withDeleted = await repository.find(
        const ItemQuery(includeDeleted: true),
      );
      expect(withDeleted.total, 3);

      await repository.restore(2);
      visible = await repository.find(const ItemQuery());
      expect(visible.total, 3);
    });

    test('физическое удаление стирает запись навсегда', () async {
      final repository = InMemoryItemRepository(
        items: [testItem(1), testItem(2)],
      );

      await repository.hardDelete(1);
      final result = await repository.find(
        const ItemQuery(includeDeleted: true),
      );
      expect(result.total, 1);
      expect(result.items.single.id, 2);
    });

    test('deleteMany исправлен: удаляет только существующие записи', () async {
      final repository = InMemoryItemRepository(
        items: [testItem(1), testItem(2), testItem(3)],
      );

      final count = await repository.deleteMany([1, 2, 999]);
      expect(count, 2);

      final visible = await repository.find(const ItemQuery());
      expect(visible.total, 1);
      expect(visible.items.single.id, 3);

      final secondRun = await repository.deleteMany([1, 2]);
      expect(secondRun, 0);
    });

    test('findById возвращает запись или null', () async {
      final repository = InMemoryItemRepository(
        items: [testItem(1, title: 'Куртка')],
      );
      expect((await repository.findById(1))?.title, 'Куртка');
      expect(await repository.findById(42), isNull);
    });
  });

  group('InMemoryBrandRepository', () {
    test('поиск по названию и стране, фильтр по году', () async {
      final repository = InMemoryBrandRepository();

      final byCountry = await repository.find(
        const BrandQuery(search: 'Италия'),
      );
      expect(byCountry.total, 1);
      expect(byCountry.items.single.name, 'Milano Moda');

      final byName = await repository.find(
        const BrandQuery(search: 'eco', size: 25),
      );
      expect(byName.total, 1);

      final founded = await repository.find(const BrandQuery(yearFrom: 2010));
      expect(founded.items.every((b) => b.foundedYear >= 2010), isTrue);
    });

    test('множественное удаление возвращает количество', () async {
      final repository = InMemoryBrandRepository();
      final count = await repository.deleteMany([1, 2, 3]);
      expect(count, 3);
      final visible = await repository.find(const BrandQuery());
      expect(visible.total, seedBrands.length - 3);
    });
  });

  group('Параметры адреса', () {
    test('ItemQuery разбирается из адреса и сериализуется обратно', () {
      final uri = Uri.parse(
        '/items?search=джинсы&categoryId=2&brandId=3&priceFrom=1000'
        '&priceTo=7000&sort=year,desc&page=3&size=25&showDeleted=true',
      );
      final query = ItemQuery.fromQueryParameters(uri.queryParameters);
      expect(query.search, 'джинсы');
      expect(query.categoryId, 2);
      expect(query.brandId, 3);
      expect(query.priceFrom, 1000);
      expect(query.priceTo, 7000);
      expect(query.sortField, 'year');
      expect(query.sortAscending, isFalse);
      expect(query.page, 3);
      expect(query.size, 25);
      expect(query.includeDeleted, isTrue);

      final restored = ItemQuery.fromQueryParameters(
        Uri.parse(query.toLocation()).queryParameters,
      );
      expect(restored, query);
    });

    test('смена фильтра сбрасывает страницу и умеет очищать значение', () {
      const query = ItemQuery(page: 7, categoryId: 2, search: 'платье');
      final next = query.copyWith(search: 'худи');
      expect(next.page, 1);
      expect(next.search, 'худи');

      final cleared = next.copyWith(categoryId: null);
      expect(cleared.categoryId, isNull);
      expect(cleared.search, 'худи');
    });

    test('некорректный размер страницы заменяется на 10', () {
      final query = ItemQuery.fromQueryParameters({'size': '33'});
      expect(query.size, 10);
    });
  });
}
