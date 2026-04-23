import 'dart:math';

import '../core/utils/app_constants.dart';
import '../domain/entities/recommendation_result.dart';
import '../models/destination.dart';
import '../models/user_preferences.dart';
import 'user_profile_service.dart';

export '../domain/entities/recommendation_result.dart';

class RecommenderService {
  final Map<String, List<Map<String, dynamic>>> similarPlaces;
  final UserProfileService? userProfileService;
  _TfIdfIndex? _index;

  RecommenderService(this.similarPlaces, {this.userProfileService});

  List<RecommendationResult> recommendByPreferences(
    UserPreferences prefs,
    List<Destination> destinations, {
    int topK = 10,
  }) {
    _index ??= _TfIdfIndex.build(destinations);

    final queryTextVec = _index!.queryVector(_queryTerms(prefs));
    final queryNumVec = _numericQueryVector(prefs);
    final scored = <RecommendationResult>[];

    for (final dest in destinations) {
      final docTextVec = _index!.documentVector(dest.id);
      if (docTextVec == null) continue;

      final textScore = _cosineSimilarity(queryTextVec, docTextVec);
      final numericScore =
          _cosineSimilarity(queryNumVec, _numericDocVector(dest));

      final blended = AppConstants.textScoreWeight * textScore +
          AppConstants.numericScoreWeight * numericScore;

      if (blended <= 0) continue;

      final affinityBoost = userProfileService?.affinityBoostFor(dest) ?? 0.0;
      final seasonBonus = dest.bestSeason
              .map(_norm)
              .contains(_norm(prefs.season))
          ? 0.06
          : 0.0;
      final budgetBonus =
          _budgetBonus(_norm(dest.priceTier), _norm(prefs.budget));

      final finalScore =
          blended + affinityBoost + seasonBonus + budgetBonus;

      scored.add(
        RecommendationResult(
          destination: dest,
          score: finalScore,
          reasons: _buildReasons(
            dest,
            prefs,
            textScore,
            numericScore,
            affinityBoost > 0,
          ),
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    return _diversify(
      scored,
      topK: topK,
      maxPerDistrict: AppConstants.maxResultsPerDistrict,
      maxPerCategory: AppConstants.maxResultsPerCategory,
    );
  }

  List<RecommendationResult> similarToDestination(
    Destination seed,
    List<Destination> destinations, {
    int topK = 4,
  }) {
    _index ??= _TfIdfIndex.build(destinations);

    final seedVec = _index!.documentVector(seed.id);
    if (seedVec == null) return [];

    final explicitIds = (similarPlaces[seed.id.toLowerCase()] ?? [])
        .map((e) => (e['id'] as String).toLowerCase())
        .toSet();

    final scored = <RecommendationResult>[];

    for (final dest in destinations) {
      if (dest.id == seed.id) continue;

      final docVec = _index!.documentVector(dest.id);
      if (docVec == null) continue;

      double sim = _cosineSimilarity(seedVec, docVec);
      final reasons = <String>[];

      if (explicitIds.contains(dest.id.toLowerCase())) {
        sim += 0.25;
        reasons.add('Listed as a similar destination in our dataset');
      }

      if (sim <= 0) continue;

      final sd = _norm(seed.district ?? '');
      final dd = _norm(dest.district ?? '');
      if (sd.isNotEmpty && sd == dd) {
        sim += 0.05;
        reasons.add('Located in the same district');
      }

      reasons.addAll(_buildSimilarityReasons(seed, dest));

      scored.add(
        RecommendationResult(
          destination: dest,
          score: sim,
          reasons: reasons.take(4).toList(),
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  List<double> _numericDocVector(Destination dest) {
    return _l2Normalise([
      (dest.adventureLevel ?? 3) / 5.0,
      (dest.cultureLevel ?? 3) / 5.0,
      (dest.natureLevel ?? 3) / 5.0,
      _accessibilityScore(dest.accessibility),
      dest.familyFriendly == true ? 1.0 : 0.0,
    ]);
  }

  List<double> _numericQueryVector(UserPreferences prefs) {
    final activity = _norm(prefs.activity);
    final vibe = _norm(prefs.vibe);

    double adventure = 0.5;
    double culture = 0.5;
    double nature = 0.5;
    double accessibility = 0.5;
    double family = 0.5;

    switch (activity) {
      case 'adventure':
      case 'hiking':
        adventure = 0.9;
        nature = 0.8;
        break;
      case 'culture':
        culture = 1.0;
        adventure = 0.3;
        break;
      case 'wildlife':
        nature = 1.0;
        adventure = 0.6;
        break;
      case 'relaxation':
        adventure = 0.2;
        accessibility = 0.8;
        break;
      case 'lake':
        nature = 0.9;
        adventure = 0.4;
        break;
      case 'photography':
      case 'viewpoint':
        nature = 0.8;
        culture = 0.6;
        break;
    }

    switch (vibe) {
      case 'family':
        family = 1.0;
        adventure = adventure.clamp(0.0, 0.6);
        accessibility = 0.9;
        break;
      case 'adventure':
        adventure = (adventure + 0.2).clamp(0.0, 1.0);
        break;
      case 'cultural':
        culture = (culture + 0.2).clamp(0.0, 1.0);
        break;
      case 'quiet':
      case 'peaceful':
        adventure = (adventure - 0.1).clamp(0.0, 1.0);
        break;
    }

    return _l2Normalise([
      adventure,
      culture,
      nature,
      accessibility,
      family,
    ]);
  }

  double _accessibilityScore(String? a) {
    switch (_norm(a ?? '')) {
      case 'easy':
        return 1.0;
      case 'moderate':
        return 0.6;
      case 'difficult':
        return 0.2;
      case 'very difficult':
        return 0.1;
      default:
        return 0.5;
    }
  }

  List<RecommendationResult> _diversify(
    List<RecommendationResult> ranked, {
    required int topK,
    required int maxPerDistrict,
    required int maxPerCategory,
  }) {
    final districtCount = <String, int>{};
    final categoryCount = <String, int>{};
    final out = <RecommendationResult>[];

    for (final r in ranked) {
      if (out.length >= topK) break;

      final district = _norm(r.destination.district ?? 'unknown');
      final category = _norm(r.destination.primaryCategory);

      final dc = districtCount[district] ?? 0;
      final cc = categoryCount[category] ?? 0;

      if (dc >= maxPerDistrict || cc >= maxPerCategory) continue;

      districtCount[district] = dc + 1;
      categoryCount[category] = cc + 1;
      out.add(r);
    }

    if (out.length < topK) {
      final seen = out.map((r) => r.destination.id).toSet();
      for (final r in ranked) {
        if (out.length >= topK) break;
        if (!seen.contains(r.destination.id)) out.add(r);
      }
    }

    return out;
  }

  List<String> _buildReasons(
    Destination dest,
    UserPreferences prefs,
    double textScore,
    double numericScore,
    bool hasAffinityBoost,
  ) {
    final reasons = <String>[];
    final allTerms = [
      ...dest.activities.map(_norm),
      ...dest.category.map(_norm),
      ...dest.tags.map(_norm),
    ];

    if (_activityAliases(_norm(prefs.activity)).any(allTerms.contains)) {
      reasons.add(_activityReason(prefs.activity));
    }

    if (dest.bestSeason.map(_norm).contains(_norm(prefs.season))) {
      reasons.add('Best visited during ${_pretty(prefs.season)}');
    }

    if (_norm(dest.priceTier) == _norm(prefs.budget)) {
      reasons.add(_budgetReason(_norm(prefs.budget)));
    }

    if (_vibeAliases(_norm(prefs.vibe)).any(allTerms.contains)) {
      reasons.add(_vibeReason(prefs.vibe));
    }

    if (hasAffinityBoost) {
      reasons.add('Matches your past exploration interests');
    }

    if (reasons.isEmpty) {
      reasons.add(
        'Strong content match (text: ${textScore.toStringAsFixed(2)}, features: ${numericScore.toStringAsFixed(2)})',
      );
    }

    return reasons.take(4).toList();
  }

  List<String> _buildSimilarityReasons(Destination seed, Destination dest) {
    final reasons = <String>[];

    final sharedActs = seed.activities.map(_norm).toSet()
      ..retainAll(dest.activities.map(_norm).toSet());
    if (sharedActs.isNotEmpty) {
      reasons.add(
        'Shares activities: ${sharedActs.take(2).map(_pretty).join(', ')}',
      );
    }

    final sharedCats = seed.category.map(_norm).toSet()
      ..retainAll(dest.category.map(_norm).toSet());
    if (sharedCats.isNotEmpty) {
      reasons.add('Similar destination category');
    }

    if (_norm(seed.priceTier) == _norm(dest.priceTier)) {
      reasons.add('Similar budget level');
    }

    final sharedSeasons = seed.bestSeason.map(_norm).toSet()
      ..retainAll(dest.bestSeason.map(_norm).toSet());
    if (sharedSeasons.isNotEmpty) {
      reasons.add('Best visited in a similar season');
    }

    return reasons;
  }

  double _budgetBonus(String actual, String preferred) {
    if (actual == preferred) return 0.06;

    const order = ['budget', 'medium', 'premium'];
    final a = order.indexOf(actual);
    final b = order.indexOf(preferred);

    if (a == -1 || b == -1) return 0;
    return (a - b).abs() == 1 ? 0.02 : 0;
  }

  List<String> _queryTerms(UserPreferences prefs) => [
        ..._activityAliases(_norm(prefs.activity)),
        ..._vibeAliases(_norm(prefs.vibe)),
        _norm(prefs.budget),
        _norm(prefs.season),
      ];

  List<String> _activityAliases(String a) {
    const map = <String, List<String>>{
      'culture': [
        'culture',
        'cultural',
        'heritage',
        'village',
        'museum',
        'pilgrimage',
      ],
      'hiking': ['hiking', 'trekking', 'adventure', 'trek', 'trail'],
      'adventure': [
        'adventure',
        'hiking',
        'trekking',
        'rafting',
        'paragliding',
        'zipline',
      ],
      'wildlife': ['wildlife', 'bird', 'forest', 'nature', 'conservation'],
      'relaxation': ['relax', 'peaceful', 'lake', 'scenic', 'retreat'],
      'lake': ['lake', 'boating', 'waterside', 'scenic'],
      'photography': ['photography', 'viewpoint', 'panorama', 'scenic'],
      'viewpoint': ['viewpoint', 'panorama', 'sunrise', 'scenic'],
    };
    return map[a] ?? [a];
  }

  List<String> _vibeAliases(String v) {
    const map = <String, List<String>>{
      'family': ['family', 'easy', 'safe', 'picnic'],
      'adventure': ['adventure', 'thrill', 'trekking', 'rafting'],
      'cultural': ['culture', 'heritage', 'local', 'traditional'],
      'quiet': ['quiet', 'peaceful', 'relax', 'retreat'],
      'peaceful': ['peaceful', 'quiet', 'relax', 'retreat'],
    };
    return map[v] ?? [v];
  }

  String _activityReason(String raw) =>
      'Matches your interest in ${_pretty(raw)}';

  String _budgetReason(String raw) =>
      'Fits your ${_pretty(raw)} budget';

  String _vibeReason(String raw) =>
      'Offers a ${_pretty(raw)} vibe';

  String _pretty(String s) {
    if (s.isEmpty) return s;
    final t = s.trim();
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  String _norm(String s) => s.trim().toLowerCase();

  List<double> _l2Normalise(List<double> v) {
    final mag = sqrt(v.fold(0.0, (sum, x) => sum + x * x));
    if (mag == 0) return List<double>.filled(v.length, 0.0);
    return v.map((e) => e / mag).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dot = 0.0;
    double ma = 0.0;
    double mb = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      ma += a[i] * a[i];
      mb += b[i] * b[i];
    }

    if (ma == 0 || mb == 0) return 0.0;
    return dot / (sqrt(ma) * sqrt(mb));
  }
}

class _TfIdfIndex {
  final Map<String, int> vocab;
  final Map<String, List<double>> docVectors;

  _TfIdfIndex({
    required this.vocab,
    required this.docVectors,
  });

  factory _TfIdfIndex.build(List<Destination> destinations) {
    final vocab = <String, int>{};
    final docTerms = <String, List<String>>{};

    for (final d in destinations) {
      final terms = <String>[
        ...d.category,
        ...d.activities,
        ...d.tags,
        d.description,
        d.type,
        d.district ?? '',
      ].expand((e) => _tokenize(e)).toList();

      docTerms[d.id] = terms;

      for (final t in terms) {
        vocab.putIfAbsent(t, () => vocab.length);
      }
    }

    final df = List<int>.filled(vocab.length, 0);
    for (final terms in docTerms.values) {
      final seen = <int>{};
      for (final t in terms) {
        final idx = vocab[t];
        if (idx != null && seen.add(idx)) {
          df[idx]++;
        }
      }
    }

    final nDocs = destinations.length;
    final docVectors = <String, List<double>>{};

    for (final entry in docTerms.entries) {
      final tf = List<double>.filled(vocab.length, 0.0);
      for (final t in entry.value) {
        final idx = vocab[t];
        if (idx != null) tf[idx] += 1.0;
      }

      for (int i = 0; i < tf.length; i++) {
        if (tf[i] == 0) continue;
        final idf = log((nDocs + 1) / (df[i] + 1)) + 1.0;
        tf[i] = tf[i] * idf;
      }

      final mag = sqrt(tf.fold(0.0, (s, x) => s + x * x));
      docVectors[entry.key] =
          mag == 0 ? tf : tf.map((e) => e / mag).toList();
    }

    return _TfIdfIndex(vocab: vocab, docVectors: docVectors);
  }

  List<double>? documentVector(String id) => docVectors[id];

  List<double> queryVector(List<String> terms) {
    final vec = List<double>.filled(vocab.length, 0.0);
    for (final t in terms.expand(_tokenize)) {
      final idx = vocab[t];
      if (idx != null) vec[idx] += 1.0;
    }

    final mag = sqrt(vec.fold(0.0, (s, x) => s + x * x));
    return mag == 0 ? vec : vec.map((e) => e / mag).toList();
  }

  static List<String> _tokenize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
  }
}