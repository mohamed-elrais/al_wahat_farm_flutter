import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.isActive,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final bool isActive;
  final String? phoneNumber;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        id: json['id']! as String,
        fullName: json['full_name']! as String,
        isActive: json['is_active']! as bool,
        phoneNumber: json['phone_number'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.timezone,
    this.totalAreaM2,
  });

  final String id;
  final String name;
  final String code;
  final String timezone;
  final double? totalAreaM2;

  factory FarmSummary.fromJson(Map<String, Object?> json) => FarmSummary(
        id: json['id']! as String,
        name: json['name']! as String,
        code: json['code']! as String,
        timezone: json['timezone']! as String,
        totalAreaM2: (json['total_area_m2'] as num?)?.toDouble(),
      );
}

class FarmMembership {
  const FarmMembership({
    required this.id,
    required this.profileId,
    required this.role,
    required this.isActive,
    required this.farm,
  });

  final String id;
  final String profileId;
  final FarmRole role;
  final bool isActive;
  final FarmSummary farm;

  factory FarmMembership.fromJson(Map<String, Object?> json) => FarmMembership(
        id: json['id']! as String,
        profileId: json['profile_id']! as String,
        role: FarmRole.fromJson(json['role']! as String),
        isActive: json['is_active']! as bool,
        farm: FarmSummary.fromJson(json['farms']! as Map<String, Object?>),
      );
}

class OperationalContext {
  OperationalContext({
    required this.profile,
    required List<FarmMembership> memberships,
  }) : memberships = List<FarmMembership>.unmodifiable(memberships);

  final UserProfile profile;
  final List<FarmMembership> memberships;

  FarmMembership? membershipForFarm(String farmId) {
    for (final membership in memberships) {
      if (membership.farm.id == farmId) return membership;
    }
    return null;
  }
}

enum BootstrapBlockReason {
  profileMissing,
  profileInactive,
  noActiveOperationalMembership,
}

class BootstrapBlockedException implements Exception {
  const BootstrapBlockedException(this.reason);

  final BootstrapBlockReason reason;
}
