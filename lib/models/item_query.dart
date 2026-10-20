class ItemQuery {
  static const Object _unset = Object();
  static const List<String> allowedSortFields = ['title', 'price', 'year'];
  static const List<int> allowedPageSizes = [10, 25, 50];

  final String search;
  final int? categoryId;
  final int? brandId;
  final int? priceFrom;
  final int? priceTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ItemQuery({
    this.search = '',
    this.categoryId,
    this.brandId,
    this.priceFrom,
    this.priceTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ItemQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? brandId = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ItemQuery(
      search: search ?? this.search,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      brandId: identical(brandId, _unset) ? this.brandId : brandId as int?,
      priceFrom: identical(priceFrom, _unset)
          ? this.priceFrom
          : priceFrom as int?,
      priceTo: identical(priceTo, _unset) ? this.priceTo : priceTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      // Любое изменение условий отбора возвращает на первую страницу.
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory ItemQuery.fromQueryParameters(Map<String, String> params) {
    final rawSort = params['sort'] ?? 'title,asc';
    final parts = rawSort.split(',');
    final field = allowedSortFields.contains(parts.first)
        ? parts.first
        : 'title';
    final ascending = parts.length < 2 || parts[1] != 'desc';
    final rawSize = int.tryParse(params['size'] ?? '') ?? 10;
    final rawPage = int.tryParse(params['page'] ?? '') ?? 1;
    return ItemQuery(
      search: params['search'] ?? '',
      categoryId: int.tryParse(params['categoryId'] ?? ''),
      brandId: int.tryParse(params['brandId'] ?? ''),
      priceFrom: int.tryParse(params['priceFrom'] ?? ''),
      priceTo: int.tryParse(params['priceTo'] ?? ''),
      sortField: field,
      sortAscending: ascending,
      page: rawPage < 1 ? 1 : rawPage,
      size: allowedPageSizes.contains(rawSize) ? rawSize : 10,
      includeDeleted: params['showDeleted'] == 'true',
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search;
    if (categoryId != null) params['categoryId'] = '$categoryId';
    if (brandId != null) params['brandId'] = '$brandId';
    if (priceFrom != null) params['priceFrom'] = '$priceFrom';
    if (priceTo != null) params['priceTo'] = '$priceTo';
    if (sortField != 'title' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page > 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['showDeleted'] = 'true';
    return params;
  }

  String toLocation() {
    final params = toQueryParameters();
    return Uri(
      path: '/items',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  @override
  bool operator ==(Object other) {
    return other is ItemQuery &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.brandId == brandId &&
        other.priceFrom == priceFrom &&
        other.priceTo == priceTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
    search,
    categoryId,
    brandId,
    priceFrom,
    priceTo,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
