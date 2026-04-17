import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/user_preferences.dart';
import '../services/local_data_service.dart';
import '../services/recommender_service.dart';
import '../widgets/destination_card.dart';
import 'details_screen.dart';

class RecommendTab extends StatefulWidget {
  final List<Destination> destinations;
  final RecommenderService service;
  final Future<void> Function(Destination) onToggleSaved;
  final bool Function(Destination) isSaved;

  const RecommendTab({
    super.key,
    required this.destinations,
    required this.service,
    required this.onToggleSaved,
    required this.isSaved,
  });

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  final activityOptions = const ['viewpoint', 'hiking', 'lake', 'culture', 'adventure', 'wildlife'];
  final budgetOptions = const ['Low', 'Medium', 'High'];
  final seasonOptions = const ['All Year', 'Oct-May', 'Jun-Sep'];
  final vibeOptions = const ['quiet', 'family', 'photography'];

  String activity = 'culture';
  String budget = 'Low';
  String season = 'All Year';
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
      final key = item.destination.name.toLowerCase();
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

    if (mounted) {
      setState(() {
        _results = results;
        _busy = false;
      });
    }
  }

  Future<void> _loadCachedRecommendations() async {
    final prefs = _currentPrefs();

    final cacheKey = LocalDataService.instance.buildRecommendationCacheKey(
      prefs,
      seed: _seed,
    );

    final cached = await LocalDataService.instance.getCachedRecommendations(cacheKey);

    await LocalDataService.instance.logEvent('recommendations_loaded_from_cache', {
      'activity': prefs.activity,
      'budget': prefs.budget,
      'season': prefs.season,
      'vibe': prefs.vibe,
      'seed': _seed?.name,
      'count': cached.length,
    });

    if (mounted) {
      setState(() {
        _results = cached;
      });
    }
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
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: activity,
                            decoration: const InputDecoration(labelText: 'Activity'),
                            items: activityOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => activity = v ?? activity),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: budget,
                            decoration: const InputDecoration(labelText: 'Budget'),
                            items: budgetOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => budget = v ?? budget),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: season,
                            decoration: const InputDecoration(labelText: 'Season'),
                            items: seasonOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => season = v ?? season),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: vibe,
                            decoration: const InputDecoration(labelText: 'Trip vibe'),
                            items: vibeOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => vibe = v ?? vibe),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Destination>(
                            value: _seed,
                            decoration: const InputDecoration(labelText: 'Starting point for similar places'),
                            items: widget.destinations
                                .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                                .toList(),
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.explore_outlined),
                              label: const Text('Generate Recommendations'),
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
                  const SizedBox(height: 12),
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
}