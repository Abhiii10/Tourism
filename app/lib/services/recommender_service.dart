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
    'viewpoint': ['sunrise', 'sunset', 'panoramic', 'view', 'ridge', 'photography'],
    'hiking': ['trek', 'trail', 'walk', 'forest', 'hill', 'trekking'],
    'lake': ['boating', 'wetland', 'water', 'fishing'],
    'culture': ['gurung', 'magar', 'newar', 'heritage', 'museum', 'village'],
    'adventure': ['cycling', 'cave', 'zip', 'climb', 'paragliding'],
    'wildlife': ['bird', 'wetland', 'conservation', 'forest'],
    'relaxation': ['peaceful', 'quiet', 'nature'],
    'photography': ['view', 'mountain', 'panoramic', 'scenic'],
  };

  List<RecommendationResult> recommendByPreferences(
    UserPreferences prefs,
    List<Destination> all, {
    int topK = 8,
  }) {
    final results = <RecommendationResult>[];

    for (final d in all) {
      double score = 0;
      final reasons = <String>[];

      final tokens = _tokenize([
        ...d.category,
        ...d.activities,
        ...d.tags,
        d.shortDescription,
        d.fullDescription,
      ]);

      final activity = prefs.activity.toLowerCase().trim();
      final budget = prefs.budget.toLowerCase().trim();
      final season = prefs.season.toLowerCase().trim();
      final vibe = prefs.vibe.toLowerCase().trim();

      /// 🔥 1. ACTIVITY MATCH (strongest)
      if (tokens.contains(activity)) {
        score += 4.0;
        reasons.add('Matches your interest in ${prefs.activity}');
      } else {
        for (final s in _activitySynonyms[activity] ?? []) {
          if (tokens.contains(s)) {
            score += 1.5;
            reasons.add('Related to ${prefs.activity}');
            break;
          }
        }
      }

      /// 🔥 2. CATEGORY MATCH
      if (d.category.map((e) => e.toLowerCase()).contains(activity)) {
        score += 2.5;
      }

      /// 🔥 3. BUDGET MATCH
      if ((d.budgetLevel ?? '').toLowerCase() == budget) {
        score += 2.0;
        reasons.add('Fits your ${prefs.budget} budget');
      }

      /// 🔥 4. SEASON MATCH
      final seasons = d.bestSeason.map((e) => e.toLowerCase()).toList();
      if (seasons.contains(season)) {
        score += 1.8;
        reasons.add('Best visited in ${prefs.season}');
      }

      /// 🔥 5. VIBE MATCH
      if (tokens.contains(vibe)) {
        score += 1.5;
        reasons.add('Good for a ${prefs.vibe} experience');
      }

      /// 🔥 6. TAG BONUS
      final tagMatches = d.tags
          .map((t) => t.toLowerCase())
          .where((t) => tokens.contains(t))
          .length;

      score += tagMatches * 0.3;

      /// 🔥 7. MIN SCORE FILTER
      if (score < 1.5) continue;

      /// fallback reason
      if (reasons.isEmpty) {
        reasons.add('General match based on destination features');
      }

      results.add(
        RecommendationResult(
          destination: d,
          score: score,
          reasons: reasons,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }

  List<RecommendationResult> similarToDestination(
    Destination seed,
    List<Destination> all, {
    int topK = 8,
  }) {
    final byName = {
      for (final d in all) d.name.toLowerCase(): d,
    };

    final similar = _similarPlaces[seed.name] ?? [];

    return similar.take(topK).map((entry) {
      final name = (entry['name'] ?? '').toString();
      final destination = byName[name.toLowerCase()];
      if (destination == null) return null;

      return RecommendationResult(
        destination: destination,
        score: (entry['score'] as num?)?.toDouble() ?? 0,
        reasons: [
          'Similar to ${seed.name}',
          'Based on offline similarity mapping',
        ],
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