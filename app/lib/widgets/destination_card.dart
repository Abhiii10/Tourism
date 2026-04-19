import 'package:flutter/material.dart';

import '../models/destination.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final List reasons;
  final String scoreLabel;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.reasons,
    required this.scoreLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tags = {
      ...destination.culturalTagList,
      ...destination.amenityList,
    }.take(3).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 TOP ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ICON (improved)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primaryContainer.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.landscape_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// NAME + META
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MetaChip(label: destination.type),
                            _MetaChip(label: _budgetLabel(destination.priceTier)),
                            _MetaChip(label: destination.bestSeasonText),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// 🔥 SCORE BADGE (IMPROVED)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scoreLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// DESCRIPTION
              Text(
                destination.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),

              /// TAGS
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map((tag) => _TagChip(label: tag))
                      .toList(),
                ),
              ],

              /// 🔥 WHY RECOMMENDED (MAJOR UPGRADE)
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.45),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Why recommended",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      ...reasons.take(3).map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• "),
                              Expanded(
                                child: Text(
                                  r,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              /// 🔥 CTA (IMPROVED)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _budgetLabel(String value) {
    switch (value.toLowerCase()) {
      case 'budget':
        return 'Low budget';
      case 'medium':
        return 'Moderate';
      case 'premium':
        return 'Premium';
      default:
        return value;
    }
  }
}

/// 🔹 META CHIP
class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// 🔹 TAG CHIP
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}