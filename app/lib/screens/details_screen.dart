import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/accommodation.dart';
import '../models/destination.dart';

class DetailsScreen extends StatelessWidget {
  final Destination destination;
  final List<String> reasons;
  final List<Accommodation> accommodations;

  const DetailsScreen({
    super.key,
    required this.destination,
    required this.reasons,
    required this.accommodations,
  });

  Future<void> _openMap(BuildContext context) async {
    if (destination.latitude == null || destination.longitude == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${destination.latitude},${destination.longitude}',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map.')),
      );
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    if (destination.latitude == null || destination.longitude == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = <String>{
      ...destination.tags,
      ...destination.activities,
    }.toList()
      ..sort();

    final matchedAccommodations = accommodations
        .where((a) => a.destinationId == destination.id)
        .toList()
      ..sort((a, b) {
        int typeRank(String? type) {
          switch ((type ?? '').toLowerCase()) {
            case 'homestay':
              return 0;
            case 'lodge':
              return 1;
            case 'guesthouse':
              return 2;
            case 'hotel':
              return 3;
            case 'resort':
              return 4;
            default:
              return 5;
          }
        }

        int priceRank(String? price) {
          switch ((price ?? '').toLowerCase()) {
            case 'budget':
              return 0;
            case 'medium':
              return 1;
            case 'premium':
              return 2;
            default:
              return 3;
          }
        }

        final byType = typeRank(a.type).compareTo(typeRank(b.type));
        if (byType != 0) return byType;

        final byPrice = priceRank(a.priceRange).compareTo(priceRank(b.priceRange));
        if (byPrice != 0) return byPrice;

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 280,
            title: Text(destination.name),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/pokhara.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.12),
                          Colors.black.withOpacity(0.62),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoBadge(label: _labelize(destination.primaryCategory)),
                            _InfoBadge(label: destination.bestSeasonText),
                            if (destination.budgetLevel != null)
                              _InfoBadge(label: _labelize(destination.budgetLevel!)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (destination.locationText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.place_outlined, size: 18),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  destination.locationText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(destination.displayDescription),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (reasons.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Why recommended',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                ...reasons.map(
                                  (r) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.check_circle_outline),
                                    title: Text(r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (tags.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Highlights',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags
                                      .take(12)
                                      .map((t) => Chip(label: Text(_labelize(t))))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                destination.latitude != null &&
                                        destination.longitude != null
                                    ? '${destination.latitude}, ${destination.longitude}'
                                    : 'Coordinates not available',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: destination.latitude != null &&
                                              destination.longitude != null
                                          ? () => _openMap(context)
                                          : null,
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text('Open Map'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: destination.latitude != null &&
                                              destination.longitude != null
                                          ? () => _openDirections(context)
                                          : null,
                                      icon: const Icon(Icons.directions_outlined),
                                      label: const Text('Directions'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accommodations',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              if (matchedAccommodations.isEmpty)
                                const Text(
                                  'No accommodation data available for this destination yet.',
                                )
                              else
                                ...matchedAccommodations.map(
                                  (acc) => Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                acc.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (acc.type != null &&
                                                acc.type!.trim().isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  _labelize(acc.type!),
                                                ),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            if (acc.priceRange != null &&
                                                acc.priceRange!.trim().isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  _labelize(acc.priceRange!),
                                                ),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            if ((acc.type ?? '').toLowerCase() ==
                                                'homestay')
                                              const Chip(
                                                label: Text('Community Stay'),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                          ],
                                        ),
                                        if (acc.locationNote != null &&
                                            acc.locationNote!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(top: 2),
                                                child: Icon(
                                                  Icons.location_on_outlined,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(acc.locationNote!.trim()),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (acc.amenities.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: acc.amenities
                                                .where((a) => a.trim().isNotEmpty)
                                                .take(5)
                                                .map(
                                                  (a) => Chip(
                                                    label: Text(_labelize(a)),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                        if (acc.phone != null &&
                                            acc.phone!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(top: 2),
                                                child: Icon(
                                                  Icons.phone_outlined,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(acc.phone!.trim()),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Text(
                                          'Source: ${acc.source} • Confidence: ${_labelize(acc.confidence)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade700,
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

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelize(String value) {
    if (value.isEmpty) return value;

    final cleaned = value.replaceAll('_', ' ').trim();
    return cleaned
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;

  const _InfoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}