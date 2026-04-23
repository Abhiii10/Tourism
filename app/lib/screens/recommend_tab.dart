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
  final List<String> activityOptions = const [
    'culture',
    'hiking',
    'lake',
    'photography',
    'adventure',
    'relaxation',
    'wildlife',
    'viewpoint',
  ];

  final List<String> budgetOptions = const [
    'budget',
    'medium',
    'premium',
  ];

  final List<String> seasonOptions = const [
    'spring',
    'summer',
    'monsoon',
    'autumn',
    'winter',
  ];

  final List<String> vibeOptions = const [
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
  bool _showOnlySaved = false;

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

    try {
      final prefs = _currentPrefs();

      final ranked = widget.service.recommendByPreferences(
        prefs,
        widget.destinations,
        topK: 10,
      );

      final similar = _seed == null
          ? const <RecommendationResult>[]
          : widget.service.similarToDestination(
              _seed!,
              widget.destinations,
              topK: 4,
            );

      final merged = <RecommendationResult>[];
      final seen = <String>{};

      for (final item in [...ranked, ...similar]) {
        final key = item.destination.id.toLowerCase();
        if (seen.add(key)) {
          merged.add(item);
        }
      }

      final results = merged.take(10).toList();

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not generate recommendations.'),
        ),
      );
    }
  }

  Future<void> _loadCachedRecommendations() async {
    try {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cached.isEmpty
                ? 'No cached recommendations found.'
                : 'Loaded ${cached.length} cached recommendations.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load cached recommendations.'),
        ),
      );
    }
  }

  List<RecommendationResult> get _visibleResults {
    if (!_showOnlySaved) return _results;
    return _results.where((r) => widget.isSaved(r.destination)).toList();
  }

  String _labelize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _toggleSavedAndRefresh(Destination destination) async {
    await widget.onToggleSaved(destination);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildChoiceChips({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = option == selected;
            return ChoiceChip(
              label: Text(_labelize(option)),
              selected: active,
              onSelected: (_) => setState(() => onSelected(option)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final savedCount = _results
        .where((result) => widget.isSaved(result.destination))
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          spacing: 12,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _MetricTile(
              label: 'Results',
              value: _results.length.toString(),
              icon: Icons.explore_outlined,
            ),
            _MetricTile(
              label: 'Saved in list',
              value: savedCount.toString(),
              icon: Icons.bookmark_outline,
            ),
            _MetricTile(
              label: 'Starting point',
              value: _seed?.name ?? 'None',
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedDropdown() {
    return DropdownButtonFormField<Destination>(
      isExpanded: true,
      initialValue: _seed,
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
    );
  }

  Widget _buildFilterCard() {
    return Card(
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
              'Choose your preferences to generate smarter destination suggestions from the offline dataset.',
            ),
            const SizedBox(height: 16),
            _buildChoiceChips(
              title: 'Activity',
              options: activityOptions,
              selected: activity,
              onSelected: (value) => activity = value,
            ),
            const SizedBox(height: 14),
            _buildChoiceChips(
              title: 'Budget',
              options: budgetOptions,
              selected: budget,
              onSelected: (value) => budget = value,
            ),
            const SizedBox(height: 14),
            _buildChoiceChips(
              title: 'Season',
              options: seasonOptions,
              selected: season,
              onSelected: (value) => season = value,
            ),
            const SizedBox(height: 14),
            _buildChoiceChips(
              title: 'Trip vibe',
              options: vibeOptions,
              selected: vibe,
              onSelected: (value) => vibe = value,
            ),
            const SizedBox(height: 16),
            _buildSeedDropdown(),
            const SizedBox(height: 16),
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
                label: Text(
                  _busy ? 'Generating...' : 'Generate Recommendations',
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
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show only saved results'),
              value: _showOnlySaved,
              onChanged: (value) {
                setState(() {
                  _showOnlySaved = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final visibleResults = _visibleResults;

    if (_results.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No recommendations yet. Choose your preferences and tap Generate Recommendations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (visibleResults.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No saved items in the current result set.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: visibleResults.map((result) {
        final destination = result.destination;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              DestinationCard(
                destination: destination,
                reasons: result.reasons,
                scoreLabel: result.score.toStringAsFixed(2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsScreen(
                        destination: destination,
                        nearbyAccommodations: widget.accommodations,
                     ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: IconButton(
                    tooltip: widget.isSaved(destination)
                        ? 'Remove from saved'
                        : 'Save destination',
                    icon: Icon(
                      widget.isSaved(destination)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: () => _toggleSavedAndRefresh(destination),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults = _visibleResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  Text(
                    _results.isEmpty
                        ? 'Recommended destinations'
                        : 'Recommended destinations (${visibleResults.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}