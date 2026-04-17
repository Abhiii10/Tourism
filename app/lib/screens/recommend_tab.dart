import 'package:flutter/material.dart';

import '../models/accommodation.dart';
import '../models/destination.dart';
import '../models/user_preferences.dart';
import '../services/local_data_service.dart';
import '../services/recommender_service.dart';
import '../widgets/destination_card.dart';
import 'details_screen.dart';

class RecommendTab extends StatefulWidget {
  final List<Destination> destinations;
  final List<Accommodation> accommodations;
  final RecommenderService service;
  final Future<void> Function(Destination) onToggleSaved;
  final bool Function(Destination) isSaved;

  const RecommendTab({
    super.key,
    required this.destinations,
    required this.accommodations,
    required this.service,
    required this.onToggleSaved,
    required this.isSaved,
  });

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  final activityOptions = const [
    'culture',
    'hiking',
    'lake',
    'photography',
    'adventure',
    'relaxation',
    'wildlife',
    'viewpoint',
  ];

  final budgetOptions = const [
    'budget',
    'medium',
    'premium',
  ];

  final seasonOptions = const [
    'spring',
    'summer',
    'monsoon',
    'autumn',
    'winter',
  ];

  final vibeOptions = const [
    'quiet',
    'family',
    'photography',
    'adventure',
    'peaceful',
    'cultural',
  ];

  String activity = 'culture';
  String budget = 'budget';
  String season = 'autumn';
  String vibe = 'quiet';

  Destination? _seed;
  List<RecommendationResult> _results = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.destinations.isNotEmpty) {
      _seed = widget.destinations.first;
    }
  }

  UserPreferences _currentPrefs() {
    return UserPreferences(
      activity: activity,
      budget: budget,
      season: season,
      vibe: vibe,
    );
  }

  Future<void> _generateRecommendations() async {
    setState(() => _busy = true);

    final prefs = _currentPrefs();

    final ranked = widget.service.recommendByPreferences(
      prefs,
      widget.destinations,
      topK: 8,
    );

    final similar = _seed == null
        ? const <RecommendationResult>[]
        : widget.service.similarToDestination(
            _seed!,
            widget.destinations,
            topK: 3,
          );

    final merged = <RecommendationResult>[];
    final seen = <String>{};

    for (final item in [...ranked, ...similar]) {
      final key = item.destination.id.toLowerCase();
      if (seen.add(key)) {
        merged.add(item);
      }
    }

    final results = merged.take(8).toList();

    final cacheKey = LocalDataService.instance.buildRecommendationCacheKey(
      prefs,
      seed: _seed,
    );

    await LocalDataService.instance.cacheRecommendations(cacheKey, results);
    await LocalDataService.instance.logEvent('recommendations_generated', {
      'activity': prefs.activity,
      'budget': prefs.budget,
      'season': prefs.season,
      'vibe': prefs.vibe,
      'seed': _seed?.name,
      'count': results.length,
    });

    if (!mounted) return;

    setState(() {
      _results = results;
      _busy = false;
    });
  }

  Future<void> _loadCachedRecommendations() async {
    final prefs = _currentPrefs();

    final cacheKey = LocalDataService.instance.buildRecommendationCacheKey(
      prefs,
      seed: _seed,
    );

    final cached =
        await LocalDataService.instance.getCachedRecommendations(cacheKey);

    await LocalDataService.instance.logEvent(
      'recommendations_loaded_from_cache',
      {
        'activity': prefs.activity,
        'budget': prefs.budget,
        'season': prefs.season,
        'vibe': prefs.vibe,
        'seed': _seed?.name,
        'count': cached.length,
      },
    );

    if (!mounted) return;

    setState(() {
      _results = cached;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel preferences',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your interests and generate destination suggestions from the local offline dataset.',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: activity,
                            decoration: const InputDecoration(
                              labelText: 'Activity',
                              border: OutlineInputBorder(),
                            ),
                            items: activityOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(_labelize(e)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => activity = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: budget,
                            decoration: const InputDecoration(
                              labelText: 'Budget',
                              border: OutlineInputBorder(),
                            ),
                            items: budgetOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(_labelize(e)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => budget = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: season,
                            decoration: const InputDecoration(
                              labelText: 'Season',
                              border: OutlineInputBorder(),
                            ),
                            items: seasonOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(_labelize(e)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => season = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: vibe,
                            decoration: const InputDecoration(
                              labelText: 'Trip vibe',
                              border: OutlineInputBorder(),
                            ),
                            items: vibeOptions
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(_labelize(e)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => vibe = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Destination>(
                            isExpanded: true,
                            value: _seed,
                            decoration: const InputDecoration(
                              labelText: 'Starting point for similar places',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.destinations
                                .map(
                                  (d) => DropdownMenuItem<Destination>(
                                    value: d,
                                    child: Text(
                                      d.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                )
                                .toList(),
                            selectedItemBuilder: (context) {
                              return widget.destinations.map((d) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    d.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (v) => setState(() => _seed = v),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _generateRecommendations,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.explore_outlined),
                              label: Text(
                                _busy
                                    ? 'Generating...'
                                    : 'Generate Recommendations',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loadCachedRecommendations,
                              icon: const Icon(Icons.history),
                              label: const Text('Load Cached Results'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_results.isNotEmpty)
                    Text(
                      'Recommended destinations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (_results.isNotEmpty) const SizedBox(height: 12),
                  if (_results.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No recommendations yet. Choose your preferences and tap Generate Recommendations.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ..._results.map(
                    (result) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          DestinationCard(
                            destination: result.destination,
                            reasons: result.reasons,
                            scoreLabel: result.score.toStringAsFixed(2),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(
                                    destination: result.destination,
                                    reasons: result.reasons,
                                    accommodations: widget.accommodations,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton.filledTonal(
                              onPressed: () async {
                                await widget.onToggleSaved(result.destination);
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: Icon(
                                widget.isSaved(result.destination)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}