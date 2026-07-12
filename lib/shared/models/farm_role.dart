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

  bool get isOperational => this != accountant;
  bool get canManageTasks => this == owner || this == agriculturalEngineer;
  bool get canReview => canManageTasks;

  String get label => switch (this) {
        owner => 'Owner',
        agriculturalEngineer => 'Agricultural engineer',
        worker => 'Worker',
        accountant => 'Accountant',
      };
}
