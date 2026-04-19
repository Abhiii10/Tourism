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
    final theme = Theme.of(context);

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
            expandedHeight: 300,
            title: Text(destination.name),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.68),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (destination.locationText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    destination.locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (destination.displayDescription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              destination.displayDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoBadge(
                              label: _labelize(destination.primaryCategory),
                            ),
                            _InfoBadge(label: destination.bestSeasonText),
                            if (destination.budgetLevel != null)
                              _InfoBadge(
                                label: _labelize(destination.budgetLevel!),
                              ),
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
                  constraints: const BoxConstraints(maxWidth: 760),
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
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),

                      _SectionCard(
                        title: 'Overview',
                        child: Text(
                          destination.displayDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (reasons.isNotEmpty)
                        _SectionCard(
                          title: 'Why recommended',
                          child: Column(
                            children: reasons.take(4).map((r) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        r,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (tags.isNotEmpty)
                        _SectionCard(
                          title: 'Highlights',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags
                                .take(12)
                                .map((t) => Chip(label: Text(_labelize(t))))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      _SectionCard(
                        title: 'Location',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.map_outlined, size: 18),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    destination.locationText.isNotEmpty
                                        ? destination.locationText
                                        : 'Location available on map',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              destination.latitude != null &&
                                      destination.longitude != null
                                  ? 'Coordinates available for map view'
                                  : 'Coordinates not available',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
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

                      const SizedBox(height: 16),

                      _SectionCard(
                        title: 'Accommodations',
                        child: matchedAccommodations.isEmpty
                            ? Text(
                                'No accommodation data available for this destination yet.',
                                style: theme.textTheme.bodyMedium,
                              )
                            : Column(
                                children: matchedAccommodations.map((acc) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: theme.colorScheme.surface,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (acc.type != null &&
                                                acc.type!.trim().isNotEmpty)
                                              Chip(
                                                label: Text(_labelize(acc.type!)),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            if (acc.priceRange != null &&
                                                acc.priceRange!.trim().isNotEmpty)
                                              Chip(
                                                label: Text(_labelize(acc.priceRange!)),
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
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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

  Widget _buildHeaderImage() {
    return Image.asset(
      'assets/images/pokhara.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.landscape, size: 56),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
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
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}