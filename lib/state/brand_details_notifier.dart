import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../repositories/brand_repository.dart';
import 'load_status.dart';

class BrandDetailsNotifier extends ChangeNotifier {
  BrandDetailsNotifier(this._repository, this.brandId);

  final BrandRepository _repository;
  final int brandId;

  Brand? _brand;
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  Brand? get brand => _brand;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _brand = await _repository.findById(brandId);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить бренд: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> softDelete() async {
    await _repository.softDelete(brandId);
    await load();
  }

  Future<void> hardDelete() async {
    await _repository.hardDelete(brandId);
    _brand = null;
    _status = LoadStatus.success;
    notifyListeners();
  }

  Future<void> restore() async {
    await _repository.restore(brandId);
    await load();
  }
}
