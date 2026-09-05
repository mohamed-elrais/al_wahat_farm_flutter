import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Notifies a shell-branch screen when the user RETURNS to it.
///
/// The app shell keeps every branch alive in an IndexedStack, so screens are
/// not re-created when the user switches sections — but TickerMode flips to
/// false for hidden branches. This mixin listens for the hidden -> visible
/// transition and calls [onSectionReturn] exactly once per return.
///
/// The initial mount does NOT trigger it (first loads belong to the screen's
/// normal lifecycle), so a route listener and a lifecycle method can never
/// double-fire the same request.
mixin SectionReturnAware<T extends StatefulWidget> on State<T> {
  ValueListenable<bool>? _sectionVisibility;
  bool _sectionVisible = true;
  bool _returnCallbackScheduled = false;

  /// Called on each hidden -> visible transition of this section.
  void onSectionReturn();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TickerMode.getNotifier(context);
    if (!identical(notifier, _sectionVisibility)) {
      _sectionVisibility?.removeListener(_handleSectionVisibility);
      _sectionVisibility = notifier..addListener(_handleSectionVisibility);
      _sectionVisible = notifier.value;
    }
  }

  void _handleSectionVisibility() {
    final visible = _sectionVisibility?.value ?? true;
    if (visible && !_sectionVisible && mounted && !_returnCallbackScheduled) {
      _returnCallbackScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _returnCallbackScheduled = false;
        if (mounted && (_sectionVisibility?.value ?? true)) {
          onSectionReturn();
        }
      });
    }
    _sectionVisible = visible;
  }

  @override
  void dispose() {
    _sectionVisibility?.removeListener(_handleSectionVisibility);
    super.dispose();
  }
}
