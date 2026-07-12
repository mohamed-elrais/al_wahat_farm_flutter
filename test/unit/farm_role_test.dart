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
}
