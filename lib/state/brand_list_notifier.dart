import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/page_result.dart';
import '../repositories/brand_repository.dart';
import 'load_status.dart';

class BrandListNotifier extends ChangeNotifier {
  BrandListNotifier(this._repository);

  final BrandRepository _repository;

  BrandQuery _query = const BrandQuery();
  PageResult<Brand> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = <int>{};
  bool _forceError = false;
  int _request = 0;

  BrandQuery get query => _query;
  PageResult<Brand> get result => _result;
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
      _error = 'Не удалось загрузить список брендов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(BrandQuery next) async {
    _query = next;
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
      _fail('Не удалось удалить выбранные бренды: $e');
      return;
    }
    await load();
  }

  Future<void> softDelete(int id) async {
    try {
      await _repository.softDelete(id);
      _selected.remove(id);
    } catch (e) {
      _fail('Не удалось удалить бренд: $e');
      return;
    }
    await load();
  }

  Future<void> hardDelete(int id) async {
    try {
      await _repository.hardDelete(id);
      _selected.remove(id);
    } catch (e) {
      _fail('Не удалось удалить бренд навсегда: $e');
      return;
    }
    await load();
  }

  Future<void> restore(int id) async {
    try {
      await _repository.restore(id);
    } catch (e) {
      _fail('Не удалось восстановить бренд: $e');
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
