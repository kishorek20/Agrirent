// lib/widgets/search_suggestion_overlay.dart
import 'package:flutter/material.dart';
import '../services/search_ranking_service.dart';
import '../utils/app_theme.dart';

class SearchSuggestionOverlay extends StatelessWidget {
  final List<SuggestionItem> suggestions;
  final ValueChanged<SuggestionItem> onSelected;

  const SearchSuggestionOverlay({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = suggestions[index];
            IconData iconData;
            Color iconColor;

            switch (item.category) {
              case 'Category':
                iconData = Icons.agriculture;
                iconColor = AppTheme.primaryGreen;
                break;
              case 'Brand':
                iconData = Icons.verified;
                iconColor = AppTheme.skyBlue;
                break;
              case 'Location':
                iconData = Icons.location_on;
                iconColor = AppTheme.accentOrange;
                break;
              case 'Vehicle':
              default:
                iconData = Icons.search;
                iconColor = Colors.grey.shade600;
                break;
            }

            return ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 18, color: iconColor),
              ),
              title: Text(
                item.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => onSelected(item),
            );
          },
        ),
      ),
    );
  }
}
