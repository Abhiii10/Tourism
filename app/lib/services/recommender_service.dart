import '../models/destination.dart';
import '../models/user_preferences.dart';

class RecommendationResult {
  final Destination destination;
  final double score;
  final List<String> reasons;

  const RecommendationResult({
    required this.destination,
    required this.score,
    required this.reasons,
  });
}

class RecommenderService {
  final Map<String, List<Map<String, dynamic>>> _similarPlaces;

  RecommenderService(this._similarPlaces);

  static final Map<String, List<String>> _activitySynonyms = {
    'viewpoint': ['sunrise', 'sunset', 'panoramic', 'view', 'ridge'],
    'hiking': ['trek', 'trail', 'walk', 'forest', 'hill'],
    'lake': ['boating', 'wetland', 'water', 'fish'],
    'culture': ['gurung', 'magar', 'newar', 'heritage', 'museum', 'village'],
    'adventure': ['cycling', 'cave', 'zip', 'climb', 'paragliding'],
    'wildlife': ['bird', 'wetland', 'conservation', 'forest'],
  };

  List<RecommendationResult> recommendByPreferences(
    UserPreferences prefs,
    List<Destination> all, {
    int topK = 8,
  }) {
    final scored = all.map((d) {
      final reasons = <String>[];
      double score = 0;

      final tokens = _tokenize([
        d.type,
        d.description,
        d.amenities,
        d.culturalTags,
      ]);

      final activity = prefs.activity.toLowerCase().trim();
      if (tokens.contains(activity)) {
        score += 3;
        reasons.add('Matches ${prefs.activity} activity');
      }

      for (final synonym in _activitySynonyms[activity] ?? const <String>[]) {
        if (tokens.contains(synonym)) {
          score += 0.6;
        }
      }

      if (d.priceTier.toLowerCase() == prefs.budget.toLowerCase()) {
        score += 1.5;
        reasons.add('Fits ${prefs.budget} budget');
      }

      final season = prefs.season.toLowerCase();
      final bestSeason = d.bestSeason.toLowerCase();
      if (bestSeason == 'all year') {
        score += 0.4;
      }
      if (season == bestSeason || bestSeason.contains(season) || season.contains(bestSeason)) {
        score += 1.1;
        reasons.add('Suitable for ${prefs.season}');
      }

      final vibe = prefs.vibe.toLowerCase().trim();
      if (tokens.contains(vibe)) {
        score += 1.0;
        reasons.add('Good for a ${prefs.vibe} trip');
      }

      if (reasons.isEmpty) {
        reasons.add('Broad match from destination attributes');
      }

      return RecommendationResult(destination: d, score: score, reasons: reasons);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  List<RecommendationResult> similarToDestination(
    Destination seed,
    List<Destination> all, {
    int topK = 8,
  }) {
    final byName = {for (final d in all) d.name.toLowerCase(): d};
    final similar = _similarPlaces[seed.name] ?? const [];

    return similar.take(topK).map((entry) {
      final name = (entry['name'] ?? '').toString();
      final destination = byName[name.toLowerCase()];
      if (destination == null) return null;
      return RecommendationResult(
        destination: destination,
        score: (entry['score'] as num?)?.toDouble() ?? 0,
        reasons: ['Similar to ${seed.name}', 'Uses offline similarity score'],
      );
    }).whereType<RecommendationResult>().toList();
  }

  Set<String> _tokenize(List<String> chunks) {
    return chunks
        .join(' ')
        .replaceAll('|', ' ')
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((e) => e.trim().isNotEmpty)
        .toSet();
  }
}