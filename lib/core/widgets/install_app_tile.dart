import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart' as web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web only: offers to install the app. Chromium shows its own install dialog;
/// iOS Safari has no such API, so it gets "Add to Home Screen" steps. Hidden
/// once installed and on native platforms.
class InstallAppTile extends StatefulWidget {
  const InstallAppTile({
    this.enabled = kIsWeb,
    this.isStandalone = web.isStandalone,
    this.isIos = web.isIos,
    this.canPromptInstall = web.canPromptInstall,
    this.promptInstall = web.promptInstall,
    this.installAvailable,
    super.key,
  });

  final bool enabled;
  final bool Function() isStandalone;
  final bool Function() isIos;
  final bool Function() canPromptInstall;
  final Future<bool> Function() promptInstall;

  /// Defaults to [web.installAvailableEvents].
  final Stream<void>? installAvailable;

  @override
  State<InstallAppTile> createState() => _InstallAppTileState();
}

class _InstallAppTileState extends State<InstallAppTile> {
  StreamSubscription<void>? _available;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    _available = (widget.installAvailable ?? web.installAvailableEvents())
        .listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    _available?.cancel();
    super.dispose();
  }

  Future<void> _install() async {
    final accepted = await widget.promptInstall();
    if (mounted) setState(() => _installed = accepted);
  }

  void _showIosSteps() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.installIosTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _Step(icon: Icons.ios_share, text: l10n.installIosStep1),
              _Step(icon: Icons.add_box_outlined, text: l10n.installIosStep2),
              _Step(icon: Icons.home_outlined, text: l10n.installIosStep3),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('install-ios-done'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.installIosDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _installed || widget.isStandalone()) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final VoidCallback onTap;
    final String title;
    if (widget.canPromptInstall()) {
      onTap = _install;
      title = l10n.installAppTitle;
    } else if (widget.isIos()) {
      onTap = _showIosSteps;
      title = l10n.installIosTitle;
    } else {
      return const SizedBox.shrink();
    }
    return ListTile(
      key: const Key('install-app-tile'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.install_mobile, color: AppColors.green),
      title: Text(title),
      subtitle: Text(l10n.installAppSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
