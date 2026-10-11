import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/platform/app_foreground.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart' as web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web only: tells the user a newer build is deployed and lets them reload.
///
/// An installed PWA often resumes from the background without reloading, so
/// it would keep running the old build indefinitely. This checks shortly after
/// start and whenever the app returns to the foreground. It never reloads on
/// its own, because a reload would discard unsaved form input.
class AppUpdateBanner extends StatefulWidget {
  const AppUpdateBanner({
    required this.child,
    this.enabled = kIsWeb,
    this.checkForUpdate = web.isNewerAppVersionAvailable,
    this.reload = web.reloadPage,
    this.foreground,
    this.initialDelay = const Duration(seconds: 5),
    super.key,
  });

  final Widget child;
  final bool enabled;
  final Future<bool> Function() checkForUpdate;
  final VoidCallback reload;

  /// Defaults to [appForegroundEvents].
  final Stream<void>? foreground;
  final Duration initialDelay;

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner> {
  Timer? _initialCheck;
  StreamSubscription<void>? _foreground;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    _initialCheck = Timer(widget.initialDelay, _check);
    _foreground = (widget.foreground ?? appForegroundEvents()).listen(
      (_) => _check(),
    );
  }

  Future<void> _check() async {
    if (_available) return;
    final available = await widget.checkForUpdate();
    if (available && mounted) setState(() => _available = true);
  }

  @override
  void dispose() {
    _initialCheck?.cancel();
    _foreground?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return widget.child;
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        Material(
          key: const Key('app-update-banner'),
          color: AppColors.ink,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.system_update_alt, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appUpdateAvailable,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    key: const Key('app-update-reload'),
                    onPressed: widget.reload,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(l10n.appUpdateReload),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
