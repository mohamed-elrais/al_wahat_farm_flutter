import 'package:flutter/widgets.dart';

/// Reduced-motion helpers backed by the platform accessibility setting
/// (`MediaQuery.disableAnimations`). Nonessential animations should route their
/// durations through [reducedMotionDuration] so they collapse to zero when a
/// user has asked the system to minimise motion.
extension MotionPreferences on BuildContext {
  bool get prefersReducedMotion =>
      MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  Duration reducedMotionDuration(Duration full) =>
      prefersReducedMotion ? Duration.zero : full;
}
