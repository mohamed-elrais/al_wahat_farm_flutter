// A login-free page that runs only the web QR scanner, for checking
// mobile_scanner + SturdyQrReader in a real browser:
//
//   flutter build web --release -t tool/web_harness/qr_scanner.dart \
//     --no-web-resources-cdn -o /tmp/qr_harness
//   (copy web/vendor into the output, serve it over http://localhost, open it
//   in Chrome with --use-fake-device-for-media-stream
//   --use-file-for-fake-video-capture=<qr.mjpeg>)
//
// Every decoded value is printed as `[qr-harness] detected <value>`. Add
// `?reader=stock` to the URL to compare with mobile_scanner's own loop.
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart' as web;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  if (Uri.base.queryParameters['reader'] != 'stock') web.installQrReader();
  runApp(const MaterialApp(home: _Harness()));
}

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String _last = 'waiting';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(
              onDetect: (capture) {
                final value = capture.barcodes.firstOrNull?.rawValue;
                if (value == null) return;
                debugPrint('[qr-harness] detected $value');
                setState(() => _last = value);
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ColoredBox(
                color: Colors.white,
                child: Text(_last, key: const Key('qr-harness-last')),
              ),
            ),
          ],
        ),
      );
}
