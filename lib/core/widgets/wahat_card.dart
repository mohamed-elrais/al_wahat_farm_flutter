import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class WahatCard extends StatelessWidget {
  const WahatCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.96),
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0E443214),
              blurRadius: 25,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8D7C5C),
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      );
}
