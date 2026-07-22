// lib/widgets/smart_price_widget.dart
import 'package:flutter/material.dart';
import '../services/smart_pricing_service.dart';
import '../utils/app_theme.dart';

/// A self-contained widget that shows a "Get Smart Price" button.
/// When tapped it fetches a [PriceSuggestion] and renders a beautiful
/// breakdown card.  Calls [onApply] with the suggested prices when the
/// owner taps "Apply Suggestion".
class SmartPriceWidget extends StatefulWidget {
  /// Called with (pricePerDay, pricePerHour) when owner accepts.
  final void Function(double day, double hour) onApply;

  /// Inputs from the form — pass current field values so the engine has context.
  final String? vehicleType;
  final String? state;
  final int? year;
  final List<String> features;
  final int existingBookings;
  final double existingRating;

  const SmartPriceWidget({
    super.key,
    required this.onApply,
    this.vehicleType,
    this.state,
    this.year,
    this.features = const [],
    this.existingBookings = 0,
    this.existingRating = 0,
  });

  @override
  State<SmartPriceWidget> createState() => _SmartPriceWidgetState();
}

class _SmartPriceWidgetState extends State<SmartPriceWidget>
    with SingleTickerProviderStateMixin {
  final _service = SmartPricingService();

  PriceSuggestion? _suggestion;
  bool _loading = false;
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (widget.vehicleType == null || widget.vehicleType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle type first'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _expanded = false;
      _suggestion = null;
    });
    try {
      final result = await _service.getSuggestion(
        vehicleType: widget.vehicleType!,
        state: widget.state,
        year: widget.year,
        features: widget.features,
        existingBookings: widget.existingBookings,
        existingRating: widget.existingRating,
      );
      if (mounted) {
        setState(() {
          _suggestion = result;
          _expanded = true;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate suggestion: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Trigger button ──────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _fetch,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryGreen),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_loading
                ? 'Analysing market data...'
                : '✨ Get Smart Price Suggestion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // ── Suggestion card ─────────────────────────────────────
        if (_expanded && _suggestion != null)
          FadeTransition(
            opacity: _fadeAnim,
            child: _SuggestionCard(
              suggestion: _suggestion!,
              onApply: () => widget.onApply(
                _suggestion!.suggestedDayPrice,
                _suggestion!.suggestedHourPrice,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Private card widget ──────────────────────────────────────────────────────

class _SuggestionCard extends StatefulWidget {
  final PriceSuggestion suggestion;
  final VoidCallback onApply;

  const _SuggestionCard({required this.suggestion, required this.onApply});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _showFactors = false;

  Color get _confidenceColor {
    switch (widget.suggestion.confidence) {
      case 'High':
        return AppTheme.successGreen;
      case 'Medium':
        return AppTheme.warningOrange;
      default:
        return AppTheme.greyText;
    }
  }

  IconData get _confidenceIcon {
    switch (widget.suggestion.confidence) {
      case 'High':
        return Icons.verified;
      case 'Medium':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Smart Price Suggestion',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _confidenceColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _confidenceColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_confidenceIcon, size: 12, color: _confidenceColor),
                      const SizedBox(width: 4),
                      Text(
                        '${s.confidence} Confidence',
                        style: TextStyle(
                          color: _confidenceColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price display
            Row(
              children: [
                Expanded(
                  child: _priceBox(
                    '₹${s.suggestedDayPrice.toStringAsFixed(0)}',
                    'Per Day',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _priceBox(
                    '₹${s.suggestedHourPrice.toStringAsFixed(0)}',
                    'Per Hour',
                    Icons.access_time,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Range bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fair Range',
                          style: TextStyle(color: Colors.white60, fontSize: 11)),
                      Text(
                        '₹${s.minDayPrice.toStringAsFixed(0)} – ₹${s.maxDayPrice.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  // Mini bar chart
                  SizedBox(
                    width: 80,
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Factors toggle
            GestureDetector(
              onTap: () => setState(() => _showFactors = !_showFactors),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'View pricing factors',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54),
                  ),
                  const Spacer(),
                  Icon(
                    _showFactors
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white60,
                    size: 18,
                  ),
                ],
              ),
            ),

            if (_showFactors) ...[
              const SizedBox(height: 10),
              ...s.factors.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.accentAmber, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onApply,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Apply Suggestion to Price Fields'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox(String price, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentAmber, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(price,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
