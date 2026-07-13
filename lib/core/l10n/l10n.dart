import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/widgets.dart';

export 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';

/// Ergonomic access to the generated localizations: `context.l10n.homeTitle`.
///
/// Falls back to English when no `Localizations` ancestor provides the strings
/// (for example in widget tests that do not install the delegates), so screens
/// still render instead of throwing.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
}
