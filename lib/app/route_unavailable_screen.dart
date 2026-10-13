import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown for an address the router does not know (a mistyped or outdated
/// link). Offers a way back instead of a dead end; signed-out users are sent
/// on to the login screen by the router's redirect.
class RouteUnavailableScreen extends StatelessWidget {
  const RouteUnavailableScreen({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.routeUnavailable(path),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('route-unavailable-home'),
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(context.l10n.routeUnavailableHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
