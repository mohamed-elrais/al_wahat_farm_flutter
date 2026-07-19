import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only owner and agricultural engineer manage and review tasks', () {
    expect(FarmRole.owner.canManageTasks, isTrue);
    expect(FarmRole.agriculturalEngineer.canReview, isTrue);
    expect(FarmRole.worker.canManageTasks, isFalse);
    expect(FarmRole.worker.canReview, isFalse);
    expect(FarmRole.accountant.isOperational, isFalse);
  });

  test('inventory and schedule management is manager-only', () {
    expect(FarmRole.owner.canManageInventory, isTrue);
    expect(FarmRole.agriculturalEngineer.canManageInventory, isTrue);
    expect(FarmRole.worker.canManageInventory, isFalse);
    expect(FarmRole.accountant.canManageInventory, isFalse);
    expect(FarmRole.owner.canManageSchedules, isTrue);
    expect(FarmRole.agriculturalEngineer.canManageSchedules, isTrue);
    expect(FarmRole.worker.canManageSchedules, isFalse);
    expect(FarmRole.accountant.canManageSchedules, isFalse);
  });

  test('chemical task types round-trip their backend wire values', () {
    expect(TaskType.pestControl.wireValue, 'pest_control');
    expect(TaskType.diseaseControl.wireValue, 'disease_control');
    for (final type in TaskType.values) {
      expect(TaskType.fromJson(type.wireValue), type);
    }
  });
}
