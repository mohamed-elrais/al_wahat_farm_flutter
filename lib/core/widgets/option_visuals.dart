import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:flutter/material.dart';

/// The corner mark's fill (see [OptionVisual.corner]).
const _cornerColor = Color(0xFFA3262A);

/// A filled circle in the option's colour with a white glyph (or white bars
/// for severity and priority). Decorative unless [semanticLabel] is given,
/// because the option's word is normally next to it.
class OptionBadge extends StatelessWidget {
  const OptionBadge(
    this.visual, {
    this.size = 40,
    this.inverted = false,
    this.semanticLabel,
    super.key,
  });

  final OptionVisual visual;
  final double size;

  /// White circle with a coloured glyph, for use on a coloured background
  /// (a selected chip).
  final bool inverted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fill = inverted ? Colors.white : visual.color;
    final ink = inverted ? visual.color : Colors.white;
    final bars = visual.bars;
    Widget badge = SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Center(
          child: bars == null
              ? Icon(visual.icon, size: size * 0.58, color: ink)
              : SizedBox(
                  width: size * 0.56,
                  height: size * 0.46,
                  child: CustomPaint(
                    painter: _BarsPainter(level: bars, active: ink),
                  ),
                ),
        ),
      ),
    );
    final corner = visual.corner;
    if (corner != null) {
      final markSize = size * 0.46;
      badge = SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            badge,
            PositionedDirectional(
              end: -size * 0.06,
              bottom: -size * 0.06,
              child: Container(
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  color: _cornerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: math.max(1.2, size * 0.04),
                  ),
                ),
                child: Icon(corner, size: markSize * 0.66, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    return semanticLabel == null
        ? ExcludeSemantics(child: badge)
        : Semantics(label: semanticLabel, image: true, child: badge);
  }
}

/// Severity or priority bars without the circle, for tight rows: [level] of
/// four bars in [color], the rest in the paper line colour.
class SeverityBars extends StatelessWidget {
  /// [visual] must be a severity or priority ([OptionVisual.bars]).
  const SeverityBars(this.visual, {this.height = 14, super.key});

  final OptionVisual visual;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: height * 1.25,
          height: height,
          child: CustomPaint(
            painter: _BarsPainter(
              level: visual.bars ?? 0,
              active: visual.color,
              inactive: AppColors.line,
            ),
          ),
        ),
      );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.level, required this.active, Color? inactive})
      : inactive = inactive ?? active.withOpacity(0.35);

  static const count = 4;

  final int level;
  final Color active;
  final Color inactive;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width * 0.1;
    final width = (size.width - gap * (count - 1)) / count;
    final radius = Radius.circular(width * 0.3);
    // Always rising left to right, like a phone's signal bars, in both
    // languages.
    for (var i = 0; i < count; i++) {
      final height = size.height * (i + 1) / count;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * (width + gap),
            size.height - height,
            width,
            height,
          ),
          radius,
        ),
        Paint()..color = i < level ? active : inactive,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.active != active ||
      oldDelegate.inactive != inactive;
}

/// The default way to show an option: its badge, then its word in ink.
class OptionLabel extends StatelessWidget {
  const OptionLabel(
    this.visual,
    this.label, {
    this.size = 28,
    this.style,
    this.maxLines,
    super.key,
  });

  final OptionVisual visual;
  final String label;
  final double size;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OptionBadge(visual, size: size),
          SizedBox(width: size * 0.3 + 2),
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              style: (style ?? const TextStyle())
                  .copyWith(color: style?.color ?? AppColors.ink),
            ),
          ),
        ],
      );
}

/// A status as a rounded pill: tinted with the status colour, its icon, and
/// the word in ink.
class StatusPill extends StatelessWidget {
  const StatusPill(this.visual, this.label, {super.key});

  final OptionVisual visual;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: visual.color.withOpacity(0.45)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (visual.bars == null)
                Icon(visual.icon, size: 15, color: visual.color)
              else
                SeverityBars(visual, height: 12),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// A chip for picking or filtering options. Selected, it fills with the
/// option's colour (white word, inverted badge), so the choice shows without
/// reading it.
class OptionChip extends StatelessWidget {
  const OptionChip({
    required this.visual,
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final OptionVisual visual;
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
        selected: selected,
        showCheckmark: false,
        selectedColor: visual.color,
        side: BorderSide(
          color: selected ? visual.color : visual.color.withOpacity(0.45),
        ),
        avatar: OptionBadge(visual, size: 24, inverted: selected),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        label: Text(label),
        onSelected: onSelected,
      );
}
