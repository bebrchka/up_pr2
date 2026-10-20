import '../data/seed_data.dart';
import '../models/clothing_item.dart';
import '../models/item_query.dart';
import '../models/page_result.dart';
import 'item_repository.dart';

class InMemoryItemRepository implements ItemRepository {
  InMemoryItemRepository({List<ClothingItem>? items})
    : _items = List<ClothingItem>.of(items ?? seedItems);

  final List<ClothingItem> _items;

  @override
  Future<PageResult<ClothingItem>> find(ItemQuery q) async {
    // Небольшая задержка имитирует сеть, чтобы индикатор загрузки был виден.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    var rows = _items.where((i) => q.includeDeleted || !i.isDeleted).toList();

    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (i) =>
                i.title.toLowerCase().contains(needle) ||
                i.sku.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((i) => i.categoryIds.contains(q.categoryId)).toList();
    }
    if (q.brandId != null) {
      rows = rows.where((i) => i.brandId == q.brandId).toList();
    }
    if (q.priceFrom != null) {
      rows = rows.where((i) => i.price >= q.priceFrom!).toList();
    }
    if (q.priceTo != null) {
      rows = rows.where((i) => i.price <= q.priceTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'year' => a.year.compareTo(b.year),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    // num.clamp возвращает num, поэтому верхнюю границу считаем явно.
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <ClothingItem>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<ClothingItem?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _indexOf(id);
    if (index == -1) throw StateError('Товар $id не найден');
    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final index = _indexOf(id);
    if (index == -1) throw StateError('Товар $id не найден');
    _items[index] = _items[index].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      // Исправление ошибки из методички: раньше здесь было !b[i].isDeleted.
      final index = _items.indexWhere(
        (item) => item.id == id && !item.isDeleted,
      );
      if (index != -1) {
        _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  int _indexOf(int id) => _items.indexWhere((item) => item.id == id);
}
