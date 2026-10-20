class Brand {
  final int id;
  final String name;
  final String country;
  final String city;
  final int foundedYear;
  final String website;
  final String description;
  final DateTime? deletedAt;

  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.foundedYear,
    required this.website,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Brand copyWith({
    String? name,
    String? country,
    String? city,
    int? foundedYear,
    String? website,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      foundedYear: foundedYear ?? this.foundedYear,
      website: website ?? this.website,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
