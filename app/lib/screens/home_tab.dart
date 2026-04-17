import 'package:flutter/material.dart';

import '../models/destination.dart';
import 'details_screen.dart';

class HomeTab extends StatefulWidget {
  final List<Destination> destinations;
  final VoidCallback onOpenRecommend;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenSaved;

  const HomeTab({
    super.key,
    required this.destinations,
    required this.onOpenRecommend,
    required this.onOpenMap,
    required this.onOpenSaved,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Destination> get _filteredDestinations {
    if (_query.trim().isEmpty) {
      return widget.destinations;
    }

    final q = _query.toLowerCase();

    return widget.destinations.where((d) {
      final text = [
        d.name,
        d.district ?? '',
        d.municipality ?? '',
        ...d.category,
        ...d.activities,
        ...d.tags,
        d.shortDescription,
        d.fullDescription,
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final featured = widget.destinations.take(3).toList();
    final results = _filteredDestinations;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          pinned: true,
          expandedHeight: 280,
          title: const Text('Rural Tourism Guide'),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/pokhara.png',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Text(
                    'Discover rural destinations around Gandaki through recommendations, maps, and curated local insights.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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

                    /// 🔍 SEARCH BAR
                    TextField(
                      controller: _controller,
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search destinations...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _query = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// QUICK ACTIONS
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore the app',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Use recommendations to find matching destinations, explore places on the map, and save destinations for later.',
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 420;
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: isNarrow ? 0.82 : 0.98,
                                  children: [
                                    _QuickActionCard(
                                      icon: Icons.explore_outlined,
                                      title: 'Get Recommendations',
                                      subtitle: 'Find places based on preferences',
                                      onTap: widget.onOpenRecommend,
                                    ),
                                    _QuickActionCard(
                                      icon: Icons.map_outlined,
                                      title: 'Explore Map',
                                      subtitle: 'View destinations on map',
                                      onTap: widget.onOpenMap,
                                    ),
                                    _QuickActionCard(
                                      icon: Icons.bookmark_outline,
                                      title: 'Saved Places',
                                      subtitle: 'Revisit your shortlist',
                                      onTap: widget.onOpenSaved,
                                    ),
                                    _QuickActionCard(
                                      icon: Icons.travel_explore_outlined,
                                      title: 'Rural Tourism',
                                      subtitle: 'Discover authentic local experiences',
                                      onTap: widget.onOpenRecommend,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 🔥 SEARCH RESULTS OR FEATURED
                    Text(
                      _query.isEmpty
                          ? 'Featured destinations'
                          : 'Search results (${results.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    if (_query.isEmpty)
                      ...featured.map((d) => _destinationCard(context, d))
                    else if (results.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No results found'),
                        ),
                      )
                    else
                      ...results.map((d) => _destinationCard(context, d)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _destinationCard(BuildContext context, Destination d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailsScreen(
                  destination: d,
                  reasons: const ['Opened from search'],
                  accommodations: const [],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: const Icon(Icons.terrain_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.primaryCategory} • ${d.bestSeasonText}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}