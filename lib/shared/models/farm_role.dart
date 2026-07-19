enum FarmRole {
  owner,
  agriculturalEngineer,
  worker,
  accountant;

  static FarmRole fromJson(String value) => switch (value) {
        'owner' => owner,
        'agricultural_engineer' => agriculturalEngineer,
        'worker' => worker,
        'accountant' => accountant,
        _ => throw FormatException('Unknown farm role: $value'),
      };

  String get wireValue => switch (this) {
        owner => 'owner',
        agriculturalEngineer => 'agricultural_engineer',
        worker => 'worker',
        accountant => 'accountant',
      };

  bool get isOperational => this != accountant;
  bool get canManageTasks => this == owner || this == agriculturalEngineer;
  bool get canReview => canManageTasks;

  /// Inventory items/categories are readable by every operational member;
  /// editing them (and the transaction ledger) is manager-only. Kept separate
  /// from [canManageTasks] so the sets can diverge later.
  bool get canManageInventory => this == owner || this == agriculturalEngineer;

  /// Operation schedules are visible to and editable by managers only
  /// (workers only ever see the generated tasks).
  bool get canManageSchedules => this == owner || this == agriculturalEngineer;

  String get label => switch (this) {
        owner => 'Owner',
        agriculturalEngineer => 'Agricultural engineer',
        worker => 'Worker',
        accountant => 'Accountant',
      };
}
