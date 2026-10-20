import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';

abstract interface class BrandRepository {
  Future<PageResult<Brand>> find(BrandQuery query);

  Future<Brand?> findById(int id);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
