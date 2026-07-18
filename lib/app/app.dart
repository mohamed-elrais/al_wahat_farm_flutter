import 'package:al_wahat_farm_flutter/app/router.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:flutter/material.dart';

class AlWahatApp extends StatefulWidget {
  const AlWahatApp({required this.config, this.services, super.key});

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
          builder: (context, child) => AppServicesScope(
            services: _services,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
}
