// A login-free page that runs only DeviceLocationService, for checking
// geolocator_web in a real browser:
//
//   flutter build web --release -t tool/web_harness/location.dart \
//     --no-web-resources-cdn -o /tmp/location_harness
//
// Serve it over http://localhost and open it in Chrome. Each fix is printed as
// `[loc-harness] fix <lat> <lng> ±<m>` and each failure as
// `[loc-harness] error <reason> cause=<type>: <cause>`.
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _Harness());

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _lines = <String>[];

  @override
  void initState() {
    super.initState();
    const DeviceLocationService().watch().listen(
          (fix) => _log('fix ${fix.latitude} ${fix.longitude} '
              '±${fix.accuracyMeters}'),
          onError: (Object error) => _log(error is LocationUnavailable
              ? 'error ${error.reason.name} cause=${error.cause.runtimeType}: '
                  '${error.cause}'
              : 'error untyped ${error.runtimeType}: $error'),
          onDone: () => _log('done'),
        );
  }

  void _log(String line) {
    // ignore: avoid_print
    print('[loc-harness] $line');
    setState(() => _lines.add(line));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
            body: ListView(children: [for (final l in _lines) Text(l)])),
      );
}
