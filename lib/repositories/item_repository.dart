import '../models/clothing_item.dart';
import '../models/item_query.dart';
import '../models/page_result.dart';

abstract interface class ItemRepository {
  Future<PageResult<ClothingItem>> find(ItemQuery query);

  Future<ClothingItem?> findById(int id);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
