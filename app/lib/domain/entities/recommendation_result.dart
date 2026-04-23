import '../../models/destination.dart';

class RecommendationResult {
  final Destination destination;
  final double score;
  final List<String> reasons;

  const RecommendationResult({
    required this.destination,
    required this.score,
    required this.reasons,
  });
}