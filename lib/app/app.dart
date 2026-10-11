import 'package:al_wahat_farm_flutter/app/router.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_update_banner.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:flutter/material.dart';

class AlWahatApp extends StatefulWidget {
  const AlWahatApp({required this.config, this.services, super.key});

  /// System text-scale bounds. Some Android vendors (e.g. Realme/ColorOS)
  /// default to a large font scale, which blows up the fixed-chrome layouts
  /// far beyond the iOS rendering. Accessibility scaling still works — it is
  /// just bounded so the UI cannot break.
  static const minTextScale = 0.85;
  static const maxTextScale = 1.3;

  /// The narrowest layout width the design is tuned for. Vendor "display
  /// size" zoom (e.g. Realme's density override) can shrink a phone to a
  /// ~320dp-wide canvas; text is scaled down proportionally on such devices
  /// so it occupies the same fraction of the screen as on a normal phone.
  static const designMinWidth = 360.0;

  /// The text scale actually applied: the system factor bounded to
  /// [minTextScale, maxTextScale], then normalized for zoomed-density
  /// devices narrower than [designMinWidth] (never reduced below
  /// [minTextScale] overall).
  static double effectiveTextScale(MediaQueryData media) {
    final bounded =
        media.textScaleFactor.clamp(minTextScale, maxTextScale).toDouble();
    final shortestSide = media.size.shortestSide;
    if (shortestSide <= 0 || shortestSide >= designMinWidth) return bounded;
    final compensated = bounded * (shortestSide / designMinWidth);
    return compensated < minTextScale ? minTextScale : compensated;
  }

  final AppConfig config;

  /// Process-wide services. When omitted (widget tests), an isolated in-memory
  /// bundle is used so no plugin channels are touched.
  final AppServices? services;

  @override
  State<AlWahatApp> createState() => _AlWahatAppState();
}

class _AlWahatAppState extends State<AlWahatApp> {
  late final AppServices _services = widget.services ?? _defaultServices();
  late final router = createRouter(widget.config);

  AppServices _defaultServices() {
    final store = InMemoryCacheStore();
    return AppServices(
      cacheStore: store,
      outbox: InMemoryOutboxStore(),
      pendingPhotos: InMemoryPendingPhotoStore(),
      connectivity: ConnectivityController(PlatformConnectivityService()),
      locale: LocaleController(store),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _services.locale,
        builder: (context, _) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: _services.locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaleFactor: AlWahatApp.effectiveTextScale(media),
              ),
              child: AppServicesScope(
                services: _services,
                child: AppUpdateBanner(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      );
}
