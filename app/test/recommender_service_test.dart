import 'package:flutter_test/flutter_test.dart';
import 'package:rural_tourism_app/models/destination.dart';
import 'package:rural_tourism_app/models/user_preferences.dart';
import 'package:rural_tourism_app/services/recommender_service.dart';

void main() {
  group('RecommenderService', () {
    final destinations = [
      const Destination(
        id: '1',
        name: 'Ghachok',
        type: 'Village',
        description: 'Quiet Gurung village with waterfalls and hiking trails',
        amenities: 'waterfalls|hiking|viewpoint',
        bestSeason: 'All Year',
        priceTier: 'Low',
        culturalTags: 'Gurung|quiet|village',
        lat: 28.3789,
        lon: 83.9789,
      ),
      const Destination(
        id: '2',
        name: 'Kahun Danda',
        type: 'Viewpoint',
        description: 'Scenic ridge viewpoint east of Pokhara',
        amenities: 'viewpoint|sunrise|hiking',
        bestSeason: 'Oct-May',
        priceTier: 'Low',
        culturalTags: 'nature|photography',
        lat: 28.233,
        lon: 84.03,
      ),
    ];

    final service = RecommenderService({
      'Ghachok': [
        {'name': 'Kahun Danda', 'score': 0.71}
      ]
    });

    test('returns ranked results for preferences', () {
      final prefs = const UserPreferences(
        activity: 'culture',
        budget: 'Low',
        season: 'All Year',
        vibe: 'quiet',
      );

      final results = service.recommendByPreferences(prefs, destinations);

      expect(results, isNotEmpty);
      expect(results.first.destination.name, 'Ghachok');
    });

    test('returns similar destinations from offline similarity map', () {
      final results = service.similarToDestination(destinations.first, destinations);

      expect(results, isNotEmpty);
      expect(results.first.destination.name, 'Kahun Danda');
    });
  });
}