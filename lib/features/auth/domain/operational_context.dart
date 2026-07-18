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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'full_name': fullName,
        'is_active': isActive,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
      };
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'code': code,
        'timezone': timezone,
        'total_area_m2': totalAreaM2,
      };
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
        farm: FarmSummary.fromJson(
          Map<String, Object?>.from(json['farms']! as Map),
        ),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'profile_id': profileId,
        'role': role.wireValue,
        'is_active': isActive,
        'farms': farm.toJson(),
      };
}

class OperationalContext {
  OperationalContext({
    required this.profile,
    required List<FarmMembership> memberships,
  }) : memberships = List<FarmMembership>.unmodifiable(memberships);

  final UserProfile profile;
  final List<FarmMembership> memberships;

  FarmMembership get selectedMembership {
    if (memberships.isEmpty) {
      throw StateError('Operational context has no active membership');
    }
    return memberships.first;
  }

  FarmMembership? membershipForFarm(String farmId) {
    for (final membership in memberships) {
      if (membership.farm.id == farmId) return membership;
    }
    return null;
  }

  Map<String, Object?> toCacheJson() => <String, Object?>{
        'profile': profile.toJson(),
        'memberships':
            memberships.map((m) => m.toJson()).toList(growable: false),
      };

  factory OperationalContext.fromCacheJson(Map<String, Object?> json) =>
      OperationalContext(
        profile: UserProfile.fromJson(
          Map<String, Object?>.from(json['profile']! as Map),
        ),
        memberships: (json['memberships']! as List<Object?>)
            .map((row) => FarmMembership.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
      );
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
