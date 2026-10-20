import 'package:flutter/foundation.dart';

import '../models/clothing_item.dart';
import '../repositories/item_repository.dart';
import 'load_status.dart';

class ItemDetailsNotifier extends ChangeNotifier {
  ItemDetailsNotifier(this._repository, this.itemId);

  final ItemRepository _repository;
  final int itemId;

  ClothingItem? _item;
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  ClothingItem? get item => _item;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _item = await _repository.findById(itemId);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить товар: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> softDelete() async {
    await _repository.softDelete(itemId);
    await load();
  }

  Future<void> hardDelete() async {
    await _repository.hardDelete(itemId);
    _item = null;
    _status = LoadStatus.success;
    notifyListeners();
  }

  Future<void> restore() async {
    await _repository.restore(itemId);
    await load();
  }
}
