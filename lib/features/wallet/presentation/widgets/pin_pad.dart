import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/wallet_strings.dart';

/// 6 dots + a big numeric keypad. Calls [onCompleted] when 6 digits are typed.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.busy = false,
    this.error,
    this.onBiometric,
  });

  final Future<void> Function(String pin) onCompleted;
  final bool busy;
  final String? error;
  final VoidCallback? onBiometric;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  @override
  void didUpdateWidget(covariant PinPad old) {
    super.didUpdateWidget(old);
    if (widget.error != null && widget.error != old.error) setState(() => _pin = '');
  }

  Future<void> _tap(String digit) async {
    if (widget.busy || _pin.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == 6) {
      final pin = _pin;
      await widget.onCompleted(pin);
      if (mounted) setState(() => _pin = '');
    }
  }

  void _back() {
    if (widget.busy || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 6; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: i < _pin.length ? AppColors.neonGradient : null,
              border: Border.all(color: i < _pin.length ? AppColors.cyan : AppColors.glassBorder, width: 2),
            ),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.error != null ? dots.animate(key: ValueKey(widget.error)).shakeX(hz: 5, amount: 6) : dots,
        SizedBox(
          height: 44,
          child: Center(
            child: widget.busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cyan))
                : Text(widget.error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.rose)),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _Key(label: d, onTap: () => _tap(d))],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Key(
              icon: widget.onBiometric != null ? Icons.fingerprint_rounded : null,
              onTap: widget.onBiometric ?? () {},
              semantic: WS.useBiometric,
            ),
            _Key(label: '0', onTap: () => _tap('0')),
            _Key(icon: Icons.backspace_outlined, onTap: _back, semantic: 'delete'),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap, this.semantic});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    final empty = label == null && icon == null;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 74,
        height: 74,
        child: empty
            ? null
            : Material(
                color: label != null ? AppColors.glassFill : Colors.transparent,
                shape: CircleBorder(side: BorderSide(color: label != null ? AppColors.glassBorder : Colors.transparent)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Center(
                    child: label != null
                        ? Text(label!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))
                        : Icon(icon, size: 30, color: AppColors.textSecondary, semanticLabel: semantic),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Bottom sheet asking for the PIN before a payment. Returns the PIN or null.
Future<String?> askPin(BuildContext context, {String? title}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Text(title ?? WS.enterPin, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            PinPad(onCompleted: (pin) async => Navigator.of(context).pop(pin)),
          ],
        ),
      ),
    ),
  );
}
