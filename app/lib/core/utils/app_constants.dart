abstract final class AppConstants {
  static const String dbName = 'rural_tourism_app.db';
  static const int dbVersion = 2;

  static const String destinationsAsset = 'assets/data/destinations.json';
  static const String accommodationsAsset = 'assets/data/accommodations.json';
  static const String similarPlacesAsset = 'assets/data/recommendations.json';

  static const double textScoreWeight = 0.60;
  static const double numericScoreWeight = 0.40;

  static const double maxAffinityBoost = 0.30;
  static const double affinityDecayFactor = 0.95;
  static const int coldStartThreshold = 5;

  static const double clickWeight = 1.0;
  static const double bookmarkWeight = 3.0;
  static const double dwellWeight = 2.0;
  static const int dwellThresholdSeconds = 10;

  static const int maxResultsPerDistrict = 2;
  static const int maxResultsPerCategory = 3;
}