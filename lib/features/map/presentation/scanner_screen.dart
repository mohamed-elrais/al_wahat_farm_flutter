import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/trees/data/tree_qr_repository.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef ScannerViewBuilder = Widget Function(
  BuildContext context,
  Future<void> Function(String token) onToken,
);

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    this.repository,
    this.scannerBuilder,
    this.onTreeFound,
    super.key,
  });

  final TreeQrRepository? repository;
  final ScannerViewBuilder? scannerBuilder;
  final ValueChanged<ScannedTree>? onTreeFound;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final TreeQrRepository _repository;
  bool _handling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? SupabaseTreeQrRepository(Supabase.instance.client);
  }

  Future<void> _scan(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _scanToken(raw);
  }

  Future<void> _scanToken(String raw) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final tree = await _repository.scan(raw);
      if (!mounted) return;
      if (tree != null) {
        final onTreeFound = widget.onTreeFound;
        if (onTreeFound != null) {
          onTreeFound(tree);
        } else {
          context.go('/map/tree/${tree.id}');
        }
      } else {
        setState(
          () => _error = context.l10n.scanQrInactive,
        );
      }
    } on OperationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.l10n.scanOffline,
        );
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerBuilder = widget.scannerBuilder;
    return ColoredBox(
      color: AppColors.ink,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (scannerBuilder != null)
            scannerBuilder(context, _scanToken)
          else
            MobileScanner(
              onDetect: _scan,
              errorBuilder: (_, error) => _CameraFailure(error: error),
            ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.orange, width: 4),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 112,
            child: IgnorePointer(
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
                            ? context.l10n.scanLookingUp
                            : context.l10n.scanPointCamera),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFailure extends StatelessWidget {
  const _CameraFailure({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.ink,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? context.l10n.scanCameraOff
                  : context.l10n.scanCameraUnavailable,
              key: const Key('scanner-camera-error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
}
