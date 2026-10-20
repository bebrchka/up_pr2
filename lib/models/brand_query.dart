class BrandQuery {
  static const Object _unset = Object();
  static const List<String> allowedSortFields = ['name', 'country', 'foundedYear'];
  static const List<int> allowedPageSizes = [10, 25, 50];

  final String search;
  final String? country;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BrandQuery({
    this.search = '',
    this.country,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BrandQuery copyWith({
    String? search,
    Object? country = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BrandQuery(
      search: search ?? this.search,
      country: identical(country, _unset) ? this.country : country as String?,
      yearFrom: identical(yearFrom, _unset)
          ? this.yearFrom
          : yearFrom as int?,
      yearTo: identical(yearTo, _unset) ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory BrandQuery.fromQueryParameters(Map<String, String> params) {
    final rawSort = params['sort'] ?? 'name,asc';
    final parts = rawSort.split(',');
    final field = allowedSortFields.contains(parts.first)
        ? parts.first
        : 'name';
    final ascending = parts.length < 2 || parts[1] != 'desc';
    final rawSize = int.tryParse(params['size'] ?? '') ?? 10;
    final rawPage = int.tryParse(params['page'] ?? '') ?? 1;
    final rawCountry = params['country'];
    return BrandQuery(
      search: params['search'] ?? '',
      country: rawCountry == null || rawCountry.isEmpty ? null : rawCountry,
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
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
    if (country != null && country!.isNotEmpty) params['country'] = country!;
    if (yearFrom != null) params['yearFrom'] = '$yearFrom';
    if (yearTo != null) params['yearTo'] = '$yearTo';
    if (sortField != 'name' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page > 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['showDeleted'] = 'true';
    return params;
  }

  String toLocation() {
    final params = toQueryParameters();
    return Uri(path: '/brands', queryParameters: params.isEmpty ? null : params)
        .toString();
  }

  @override
  bool operator ==(Object other) {
    return other is BrandQuery &&
        other.search == search &&
        other.country == country &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
    search,
    country,
    yearFrom,
    yearTo,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
