import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/destination.dart';

class OfflineStorage {
  static const String destinationsPath = 'assets/data/pokhara_rural_pilot.json';
  static const String similarPlacesPath = 'assets/data/recommendations.json';

  static Future<List<Destination>> loadDestinations() async {
    final raw = await rootBundle.loadString(destinationsPath);
    final decoded = jsonDecode(raw);

    if (decoded is List) {
      return decoded
          .map((e) => Destination.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    throw Exception('Unexpected destinations JSON format.');
  }

  static Future<Map<String, List<Map<String, dynamic>>>> loadSimilarPlaces() async {
    final raw = await rootBundle.loadString(similarPlacesPath);
    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw Exception('Unexpected recommendations JSON format.');
    }

    final out = <String, List<Map<String, dynamic>>>{};
    decoded.forEach((key, value) {
      out[key.toString()] = value is List
          ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
    });
    return out;
  }
}