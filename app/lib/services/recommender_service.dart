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
  final Map<String, List<Map<String, dynamic>>> similarPlaces;

  const RecommenderService(this.similarPlaces);

  List<RecommendationResult> recommendByPreferences(
    UserPreferences prefs,
    List<Destination> destinations, {
    int topK = 8,
  }) {
    final results = <RecommendationResult>[];

    for (final destination in destinations) {
      final scored = _scoreByPreferences(destination, prefs);
      if (scored.score > 0) {
        results.add(scored);
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.destination.name.toLowerCase().compareTo(
            b.destination.name.toLowerCase(),
          );
    });

    return results.take(topK).toList();
  }

  List<RecommendationResult> similarToDestination(
    Destination seed,
    List<Destination> destinations, {
    int topK = 3,
  }) {
    final seedId = seed.id.toLowerCase();

    final explicitSimilar = (similarPlaces[seedId] ?? [])
        .map((e) => (e['id'] as String).toLowerCase())
        .toSet();

    final results = <RecommendationResult>[];

    for (final candidate in destinations) {
      if (candidate.id.toLowerCase() == seedId) continue;

      final scored = _scoreSimilarity(
        seed: seed,
        candidate: candidate,
        explicitSimilarIds: explicitSimilar,
      );

      if (scored.score > 0) {
        results.add(scored);
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.destination.name.toLowerCase().compareTo(
            b.destination.name.toLowerCase(),
          );
    });

    return results.take(topK).toList();
  }

  RecommendationResult _scoreByPreferences(
    Destination destination,
    UserPreferences prefs,
  ) {
    double score = 0;
    final reasons = <String>[];

    final activity = prefs.activity.trim().toLowerCase();
    final budget = prefs.budget.trim().toLowerCase();
    final season = prefs.season.trim().toLowerCase();
    final vibe = prefs.vibe.trim().toLowerCase();

    final categories = destination.category.map(_norm).toList();
    final activities = destination.activities.map(_norm).toList();
    final tags = destination.tags.map(_norm).toList();
    final seasons = destination.bestSeason.map(_norm).toList();

    final type = _norm(destination.type);
    final priceTier = _norm(destination.priceTier);
    final primaryCategory = _safeLower(destination.primaryCategory);
    final shortDescription = _safeLower(destination.shortDescription);
    final fullDescription = _safeLower(destination.fullDescription);
    final district = _safeLower(destination.district ?? '');
    final municipality = _safeLower(destination.municipality ?? '');

    bool matchedActivity = false;
    bool matchedBudget = false;
    bool matchedSeason = false;
    bool matchedVibe = false;

    if (activities.contains(activity)) {
      score += 3.5;
      matchedActivity = true;
      reasons.add('Matches your preferred activity: ${_pretty(prefs.activity)}');
    } else if (tags.contains(activity) || categories.contains(activity)) {
      score += 2.3;
      matchedActivity = true;
      reasons.add('Closely related to ${_pretty(prefs.activity)}');
    } else if (_textContainsAny(
      [type, primaryCategory, shortDescription, fullDescription],
      [activity],
    )) {
      score += 1.2;
      matchedActivity = true;
      reasons.add('Mentions ${_pretty(prefs.activity)} in destination details');
    }

    if (priceTier == budget) {
      score += 2.4;
      matchedBudget = true;
      reasons.add('Fits your ${_pretty(prefs.budget)} budget');
    } else if (_isNearbyBudget(priceTier, budget)) {
      score += 1.0;
      matchedBudget = true;
      reasons.add('Close to your preferred budget range');
    }

    if (seasons.contains(season)) {
      score += 2.2;
      matchedSeason = true;
      reasons.add('Best visited in ${_pretty(prefs.season)}');
    } else if (seasons.any((s) => _isNearbySeason(s, season))) {
      score += 1.0;
      matchedSeason = true;
      reasons.add('Still suitable around ${_pretty(prefs.season)}');
    }

    if (tags.contains(vibe)) {
      score += 2.0;
      matchedVibe = true;
      reasons.add('Matches your trip vibe: ${_pretty(prefs.vibe)}');
    } else if (_vibeAliases(vibe).any((alias) => tags.contains(alias))) {
      score += 1.6;
      matchedVibe = true;
      reasons.add('Very close to your preferred vibe');
    } else if (_textContainsAny(
      [type, primaryCategory, shortDescription, fullDescription],
      _vibeAliases(vibe),
    )) {
      score += 1.0;
      matchedVibe = true;
      reasons.add('Destination atmosphere matches your vibe');
    }

    final richnessBoost = _featureRichnessBoost(destination);
    if (richnessBoost > 0) {
      score += richnessBoost;
    }

    if (district.isNotEmpty || municipality.isNotEmpty) {
      score += 0.15;
    }

    if (!matchedActivity && !matchedBudget && !matchedSeason && !matchedVibe) {
      score += 0.2;
      reasons.add('General rural tourism match');
    }

    return RecommendationResult(
      destination: destination,
      score: score,
      reasons: reasons.take(4).toList(),
    );
  }

  RecommendationResult _scoreSimilarity({
    required Destination seed,
    required Destination candidate,
    required Set<String> explicitSimilarIds,
  }) {
    double score = 0;
    final reasons = <String>[];

    final seedId = seed.id.toLowerCase();
    final candidateId = candidate.id.toLowerCase();

    if (explicitSimilarIds.contains(candidateId)) {
      score += 3.8;
      reasons.add('Marked as similar in the destination dataset');
    }

    final seedActivities = seed.activities.map(_norm).toSet();
    final candidateActivities = candidate.activities.map(_norm).toSet();

    final seedCategories = seed.category.map(_norm).toSet();
    final candidateCategories = candidate.category.map(_norm).toSet();

    final seedTags = seed.tags.map(_norm).toSet();
    final candidateTags = candidate.tags.map(_norm).toSet();

    final seedSeasons = seed.bestSeason.map(_norm).toSet();
    final candidateSeasons = candidate.bestSeason.map(_norm).toSet();

    final sharedActivities = seedActivities.intersection(candidateActivities);
    final sharedCategories = seedCategories.intersection(candidateCategories);
    final sharedTags = seedTags.intersection(candidateTags);
    final sharedSeasons = seedSeasons.intersection(candidateSeasons);

    if (sharedActivities.isNotEmpty) {
      score += sharedActivities.length * 1.4;
      reasons.add('Shares activities: ${sharedActivities.take(2).join(', ')}');
    }

    if (sharedCategories.isNotEmpty) {
      score += sharedCategories.length * 1.1;
      reasons.add('Shares category: ${sharedCategories.take(2).join(', ')}');
    }

    if (sharedTags.isNotEmpty) {
      score += sharedTags.length * 0.8;
      reasons.add('Has a similar travel vibe');
    }

    if (sharedSeasons.isNotEmpty) {
      score += 0.9;
      reasons.add('Best in the same season');
    }

    if (_norm(seed.type) == _norm(candidate.type)) {
      score += 1.0;
      reasons.add('Same destination type');
    }

    if (_norm(seed.priceTier) == _norm(candidate.priceTier)) {
      score += 0.8;
      reasons.add('Similar budget level');
    }

    final seedDistrict = _safeLower(seed.district ?? '');
    final candidateDistrict = _safeLower(candidate.district ?? '');
    if (seedDistrict.isNotEmpty && seedDistrict == candidateDistrict) {
      score += 0.7;
      reasons.add('Located in the same district');
    }

    if (candidateId == seedId) {
      score = 0;
      reasons.clear();
    }

    return RecommendationResult(
      destination: candidate,
      score: score,
      reasons: reasons.take(4).toList(),
    );
  }

  double _featureRichnessBoost(Destination destination) {
    final total = destination.category.length +
        destination.activities.length +
        destination.tags.length;

    if (total >= 10) return 0.6;
    if (total >= 6) return 0.35;
    if (total >= 3) return 0.18;
    return 0;
  }

  bool _isNearbyBudget(String actual, String preferred) {
    const order = ['budget', 'medium', 'premium'];
    final a = order.indexOf(actual);
    final b = order.indexOf(preferred);

    if (a == -1 || b == -1) return false;
    return (a - b).abs() == 1;
  }

  bool _isNearbySeason(String actual, String preferred) {
    final nearby = <String, Set<String>>{
      'spring': {'summer'},
      'summer': {'spring', 'monsoon'},
      'monsoon': {'summer', 'autumn'},
      'autumn': {'monsoon', 'winter'},
      'winter': {'autumn'},
    };

    return nearby[preferred]?.contains(actual) ?? false;
  }

  List<String> _vibeAliases(String vibe) {
    switch (vibe) {
      case 'quiet':
        return ['quiet', 'peaceful', 'relaxation', 'nature'];
      case 'peaceful':
        return ['peaceful', 'quiet', 'relaxation', 'nature'];
      case 'family':
        return ['family', 'culture', 'relaxation'];
      case 'photography':
        return ['photography', 'viewpoint', 'lake', 'nature'];
      case 'adventure':
        return ['adventure', 'hiking', 'wildlife', 'viewpoint'];
      case 'cultural':
        return ['cultural', 'culture', 'heritage', 'village'];
      default:
        return [vibe];
    }
  }

  bool _textContainsAny(List<String> haystacks, List<String> needles) {
    for (final hay in haystacks) {
      for (final needle in needles) {
        if (hay.contains(needle)) return true;
      }
    }
    return false;
  }

  String _norm(String value) => value.trim().toLowerCase();

  String _safeLower(String value) => value.trim().toLowerCase();

  String _pretty(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}