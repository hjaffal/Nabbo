import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Google Places Autocomplete text field.
/// Uses the Places API (New) via HTTP for lightweight autocomplete suggestions.
class PlaceAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String apiKey;
  final String? countryRestriction;

  const PlaceAutocompleteField({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.apiKey,
    this.countryRestriction,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(value);
    _debounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}'
          '&key=${widget.apiKey}'
          '&types=establishment|geocode'
          '${widget.countryRestriction != null ? '&components=country:${widget.countryRestriction}' : ''}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List? ?? [];

        if (mounted) {
          setState(() {
            _suggestions = predictions
                .take(5)
                .map((p) => _PlaceSuggestion(
                      description: p['description'] as String? ?? '',
                      mainText: p['structured_formatting']?['main_text'] as String? ?? '',
                      secondaryText: p['structured_formatting']?['secondary_text'] as String? ?? '',
                    ))
                .toList();
            _showSuggestions = _suggestions.isNotEmpty;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectSuggestion(_PlaceSuggestion suggestion) {
    _controller.text = suggestion.description;
    widget.onChanged(suggestion.description);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: 'Search for a place',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.place_outlined, size: 20),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                          setState(() => _showSuggestions = false);
                        },
                      )
                    : null),
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) {
                return InkWell(
                  onTap: () => _selectSuggestion(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.mainText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500)),
                              if (s.secondaryText.isNotEmpty)
                                Text(s.secondaryText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;

  _PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}
