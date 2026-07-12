import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _handling = false;
  String? _error;

  Future<void> _scan(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final Object? result = await Supabase.instance.client.rpc(
        'scan_tree_by_qr',
        params: <String, Object?>{'p_qr_token': raw},
      );
      if (!mounted) return;
      if (result is List && result.isNotEmpty) {
        context.go('/map');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tree found. Select it on the farm map.'),
          ),
        );
      } else {
        setState(
          () => _error = 'This QR code is not active or visible to your farm.',
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to scan while offline. Try again when connected.',
        );
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.ink,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(onDetect: _scan),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.orange, width: 4),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 112,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error ??
                        (_handling
                            ? 'Looking up tree…'
                            : 'Point the camera at a tree QR label.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
