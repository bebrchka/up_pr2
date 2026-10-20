import '../data/seed_data.dart';
import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';
import 'brand_repository.dart';

class InMemoryBrandRepository implements BrandRepository {
  InMemoryBrandRepository({List<Brand>? brands})
    : _brands = List<Brand>.of(brands ?? seedBrands);

  final List<Brand> _brands;

  @override
  Future<PageResult<Brand>> find(BrandQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    var rows = _brands.where((b) => q.includeDeleted || !b.isDeleted).toList();

    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows
          .where(
            (b) =>
                b.name.toLowerCase().contains(needle) ||
                b.country.toLowerCase().contains(needle) ||
                b.description.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null) {
      rows = rows.where((b) => b.country == q.country).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.foundedYear >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.foundedYear <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.compareTo(b.country),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Brand>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Brand?> findById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final brand in _brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _indexOf(id);
    if (index == -1) throw StateError('Бренд $id не найден');
    _brands[index] = _brands[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _brands.removeWhere((brand) => brand.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final index = _indexOf(id);
    if (index == -1) throw StateError('Бренд $id не найден');
    _brands[index] = _brands[index].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index = _brands.indexWhere(
        (brand) => brand.id == id && !brand.isDeleted,
      );
      if (index != -1) {
        _brands[index] = _brands[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  int _indexOf(int id) => _brands.indexWhere((brand) => brand.id == id);
}
