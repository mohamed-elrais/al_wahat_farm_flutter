import 'package:al_wahat_farm_flutter/app/route_unavailable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('an unknown address offers a way back to Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/no-such-page',
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, __) => const Text('home-stub')),
      ],
      errorBuilder: (_, state) => RouteUnavailableScreen(path: state.uri.path),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable: /no-such-page'), findsOneWidget);
    await tester.tap(find.byKey(const Key('route-unavailable-home')));
    await tester.pumpAndSettle();
    expect(find.text('home-stub'), findsOneWidget);
  });
}
