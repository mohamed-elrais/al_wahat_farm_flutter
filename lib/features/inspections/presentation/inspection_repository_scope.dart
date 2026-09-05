import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:flutter/widgets.dart';

class InspectionRepositoryScope extends InheritedWidget {
  const InspectionRepositoryScope({
    required this.repository,
    required super.child,
    super.key,
  });

  final InspectionRepository repository;

  static InspectionRepository? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InspectionRepositoryScope>()
      ?.repository;

  @override
  bool updateShouldNotify(InspectionRepositoryScope oldWidget) =>
      oldWidget.repository != repository;
}
