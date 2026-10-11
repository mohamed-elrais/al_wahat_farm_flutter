import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:flutter/material.dart';

/// Shown instead of the app when another tab already owns the offline
/// database and sync engine (see [TabLease]). The database is never opened
/// here, so this tab cannot interfere with queued work.
class SecondTabApp extends StatelessWidget {
  const SecondTabApp({required this.onUseHere, super.key});

  final VoidCallback onUseHere;

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = context.l10n;
            return Scaffold(
              body: PaperBackground(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: WahatCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.tab_outlined,
                                size: 40, color: AppColors.green),
                            const SizedBox(height: 12),
                            Text(
                              l10n.secondTabTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.secondTabBody,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            FilledButton(
                              key: const Key('second-tab-use-here'),
                              onPressed: onUseHere,
                              child: Text(l10n.secondTabUseHere),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
