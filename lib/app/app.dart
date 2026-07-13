import 'package:al_wahat_farm_flutter/app/router.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
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
  late final AppServices _services = widget.services ??
      AppServices(
        cacheStore: InMemoryCacheStore(),
        connectivity: ConnectivityController(PlatformConnectivityService()),
      );
  late final router = createRouter(widget.config);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Al Wahat Farm Operations',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => AppServicesScope(
          services: _services,
          child: child ?? const SizedBox.shrink(),
        ),
      );
}
