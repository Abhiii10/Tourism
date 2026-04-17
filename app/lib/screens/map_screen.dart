import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import 'details_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Destination> destinations;

  const MapScreen({
    super.key,
    required this.destinations,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Destination? _selected;

  Future<void> _openDirections(Destination destination) async {
    if (destination.lat == null || destination.lon == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.lat},${destination.lon}'
      '&travelmode=driving',
    );

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validDestinations = widget.destinations
        .where((d) => d.lat != null && d.lon != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination Map'),
      ),
      body: validDestinations.isEmpty
          ? const Center(
              child: Text('No coordinates available in dataset.'),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(28.2096, 83.9856),
                    initialZoom: 10.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rural_tourism_app',
                    ),
                    MarkerLayer(
                      markers: validDestinations.map((destination) {
                        final isSelected = _selected?.id == destination.id;

                        return Marker(
                          point: LatLng(destination.lat!, destination.lon!),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selected = destination;
                              });
                            },
                            child: Icon(
                              Icons.location_pin,
                              size: isSelected ? 42 : 36,
                              color: isSelected ? Colors.redAccent : Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.95),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        'Tap a marker to preview a destination and open directions.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),

                if (_selected != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected!.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_selected!.type} • ${_selected!.priceTier} budget • ${_selected!.bestSeason}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selected!.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailsScreen(
                                            destination: _selected!,
                                            reasons: const ['Selected from map view'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View Details'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openDirections(_selected!),
                                    icon: const Icon(Icons.directions_outlined),
                                    label: const Text('Get Directions'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}