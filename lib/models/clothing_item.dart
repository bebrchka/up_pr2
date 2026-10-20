class ClothingItem {
  final int id;
  final String title;
  final String sku;
  final int price;
  final int year;
  final int brandId;
  final List<int> categoryIds;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  const ClothingItem({
    required this.id,
    required this.title,
    required this.sku,
    required this.price,
    required this.year,
    required this.brandId,
    required this.categoryIds,
    required this.stockTotal,
    required this.stockAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  ClothingItem copyWith({
    String? title,
    String? sku,
    int? price,
    int? year,
    int? brandId,
    List<int>? categoryIds,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ClothingItem(
      id: id,
      title: title ?? this.title,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      year: year ?? this.year,
      brandId: brandId ?? this.brandId,
      categoryIds: categoryIds ?? this.categoryIds,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
