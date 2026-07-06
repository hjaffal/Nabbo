import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A searchable bottom sheet for selecting a timezone from a long list.
class TimezoneSearchSheet extends StatefulWidget {
  final List<String> timezones;
  final String selected;
  final ValueChanged<String> onSelected;

  const TimezoneSearchSheet({
    super.key,
    required this.timezones,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<TimezoneSearchSheet> createState() => _TimezoneSearchSheetState();
}

class _TimezoneSearchSheetState extends State<TimezoneSearchSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.timezones;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.timezones;
      } else {
        final lower = query.toLowerCase();
        _filtered = widget.timezones
            .where((tz) => tz.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  /// Formats "America/New_York" → "New York" with region shown separately.
  String _displayName(String tz) {
    final parts = tz.split('/');
    if (parts.length < 2) return tz;
    return parts.last.replaceAll('_', ' ');
  }

  String _regionName(String tz) {
    final parts = tz.split('/');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Select Timezone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search timezone...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No timezones found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final tz = _filtered[index];
                        final isSelected = tz == widget.selected;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryLight,
                          leading: Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          title: Text(
                            _displayName(tz),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textBlack,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _regionName(tz),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () => widget.onSelected(tz),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
