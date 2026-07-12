import 'package:al_wahat_farm_flutter/app/router.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:flutter/material.dart';

class AlWahatApp extends StatefulWidget {
  const AlWahatApp({required this.config, super.key});

  final AppConfig config;

  @override
  State<AlWahatApp> createState() => _AlWahatAppState();
}

class _AlWahatAppState extends State<AlWahatApp> {
  late final router = createRouter(widget.config);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Al Wahat Farm Operations',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      );
}
