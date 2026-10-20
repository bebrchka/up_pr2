import 'package:flutter/foundation.dart';

import '../models/clothing_item.dart';
import '../models/item_query.dart';
import '../models/page_result.dart';
import '../repositories/item_repository.dart';
import 'load_status.dart';

class ItemListNotifier extends ChangeNotifier {
  ItemListNotifier(this._repository);

  final ItemRepository _repository;

  ItemQuery _query = const ItemQuery();
  PageResult<ClothingItem> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = <int>{};
  bool _forceError = false;
  int _request = 0;

  ItemQuery get query => _query;
  PageResult<ClothingItem> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool get forceError => _forceError;

  Future<void> load() async {
    final request = ++_request;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      if (_forceError) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        throw StateError('Демонстрационный сбой сети');
      }
      final result = await _repository.find(_query);
      if (request != _request) return;
      _result = result;
      _status = LoadStatus.success;
    } catch (e) {
      if (request != _request) return;
      _error = 'Не удалось загрузить каталог: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ItemQuery next) async {
    _query = next;
    // Выделение теряет смысл при смене условий отбора.
    _selected.clear();
    await load();
  }

  Future<void> setForceError(bool value) async {
    _forceError = value;
    await load();
  }

  void toggleSelection(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    try {
      await _repository.deleteMany(_selected.toList());
      _selected.clear();
    } catch (e) {
      _fail('Не удалось удалить выбранные товары: $e');
      return;
    }
    await load();
  }

  Future<void> softDelete(int id) async {
    try {
      await _repository.softDelete(id);
      _selected.remove(id);
    } catch (e) {
      _fail('Не удалось удалить товар: $e');
      return;
    }
    await load();
  }

  Future<void> hardDelete(int id) async {
    try {
      await _repository.hardDelete(id);
      _selected.remove(id);
    } catch (e) {
      _fail('Не удалось удалить товар навсегда: $e');
      return;
    }
    await load();
  }

  Future<void> restore(int id) async {
    try {
      await _repository.restore(id);
    } catch (e) {
      _fail('Не удалось восстановить товар: $e');
      return;
    }
    await load();
  }

  void _fail(String message) {
    _error = message;
    _status = LoadStatus.error;
    notifyListeners();
  }
}
