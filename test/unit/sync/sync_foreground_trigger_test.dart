import 'dart:async';

import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_foreground_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncs once per foreground event until disposed', () async {
    final foreground = StreamController<void>();
    var syncs = 0;
    final trigger = SyncForegroundTrigger(
      foreground: foreground.stream,
      sync: () async => syncs++,
    );

    foreground
      ..add(null)
      ..add(null);
    await Future<void>.delayed(Duration.zero);
    expect(syncs, 2);

    await trigger.dispose();
    foreground.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(syncs, 2);
    await foreground.close();
  });
}
