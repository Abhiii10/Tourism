class Destination {
  final String id;
  final String name;
  final String type;
  final String description;
  final String amenities;
  final String bestSeason;
  final String priceTier;
  final String culturalTags;
  final double? lat;
  final double? lon;

  const Destination({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.amenities,
    required this.bestSeason,
    required this.priceTier,
    required this.culturalTags,
    this.lat,
    this.lon,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Destination(
      id: (json['id'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? json['category'] ?? 'Destination').toString(),
      description: (json['description'] ?? '').toString(),
      amenities: (json['amenities'] ?? '').toString(),
      bestSeason: (json['best_season'] ?? 'All Year').toString(),
      priceTier: (json['price_tier'] ?? 'Medium').toString(),
      culturalTags: (json['cultural_tags'] ?? '').toString(),
      lat: toDouble(json['lat'] ?? json['latitude']),
      lon: toDouble(json['lon'] ?? json['lng'] ?? json['longitude']),
    );
  }

  List<String> get amenityList => _splitTags(amenities);
  List<String> get culturalTagList => _splitTags(culturalTags);

  static List<String> _splitTags(String raw) => raw
      .split('|')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}