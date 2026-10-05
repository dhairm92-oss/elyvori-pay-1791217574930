import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';
import '../widgets/wallet_widgets.dart';

// ---------------------------------------------------------------- receive
class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(walletAuthProvider).valueOrNull?.profile;
    if (profile == null) return const SizedBox.shrink();
    return WalletPage(
      title: WS.receiveTitle,
      child: ListView(
        padding: const EdgeInsets.only(top: 70),
        children: [
          Text(WS.receiveHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 22),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: -8)],
              ),
              child: QrImageView(
                data: walletQrPayload(profile.phone),
                size: 230,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF4C1D95)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF0E7490)),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.92, 0.92)),
          const SizedBox(height: 22),
          Text(profile.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(profile.phone, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 26),
          NeonButton(
            label: WS.copy,
            icon: Icons.copy_rounded,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: profile.phone));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(WS.copied), behavior: SnackBarBehavior.floating));
            },
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/request'),
            icon: const Icon(Icons.request_page_rounded),
            label: Text(WS.requestTitle),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- scan
/// Scans an Elyvori Pay code. With [pick] it returns the phone to the caller,
/// otherwise it opens the send screen for that phone.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.pick = false});

  final bool pick;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _manual = TextEditingController();
  MobileScannerController? _camera;
  bool _handled = false;

  bool get _cameraSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) _camera = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  }

  @override
  void dispose() {
    _camera?.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _found(String phone) {
    if (_handled) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    if (widget.pick) {
      context.pop(phone);
    } else {
      context.pushReplacement('/send?phone=${Uri.encodeQueryComponent(phone)}');
    }
  }

  void _onDetect(BarcodeCapture capture) {
    for (final code in capture.barcodes) {
      final phone = phoneFromQr(code.rawValue ?? '');
      if (phone != null) return _found(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: WS.scanTitle,
      child: ListView(
        padding: const EdgeInsets.only(top: 70),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_camera != null)
                    MobileScanner(controller: _camera, onDetect: _onDetect)
                  else
                    Container(
                      color: AppColors.surfaceHigh,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(WS.scanUnsupported, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cyan, width: 3),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1.02, 1.02), duration: 1100.ms),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(WS.scanHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 22),
          TextField(
            controller: _manual,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: WS.recipient, prefixIcon: const Icon(Icons.dialpad_rounded)),
          ),
          const SizedBox(height: 14),
          NeonButton(
            label: WS.continueLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              final phone = phoneFromQr(_manual.text.replaceAll(' ', ''));
              if (phone == null) {
                showWalletError(context, 'invalid_phone');
                return;
              }
              _found(phone);
            },
          ),
        ],
      ),
    );
  }
}
