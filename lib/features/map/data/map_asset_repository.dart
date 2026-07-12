import 'dart:convert';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:flutter/services.dart';

class MapAssetRepository {
  const MapAssetRepository();

  Future<FarmMapData> load() async {
    final source = await rootBundle.loadString(
      'assets/data/al_wahat_map_data.json',
    );
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Farm map asset root must be an object');
    }
    return FarmMapData.fromJson(decoded);
  }
}
