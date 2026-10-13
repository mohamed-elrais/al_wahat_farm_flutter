import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:flutter/foundation.dart';

sealed class FarmHierarchyState {
  const FarmHierarchyState();
}

class FarmHierarchyIdle extends FarmHierarchyState {
  const FarmHierarchyIdle();
}

class FarmHierarchyLoading extends FarmHierarchyState {
  const FarmHierarchyLoading();
}

class FarmHierarchyReady extends FarmHierarchyState {
  const FarmHierarchyReady(this.snapshot);

  final FarmHierarchySnapshot snapshot;
}

class FarmHierarchyFailure extends FarmHierarchyState {
  const FarmHierarchyFailure(this.error);

  final Object error;
}

class FarmHierarchyController extends ChangeNotifier {
  FarmHierarchyController(this._repository);

  final FarmHierarchyRepository _repository;
  FarmHierarchyState _state = const FarmHierarchyIdle();

  FarmHierarchyState get state => _state;

  int _generation = 0;

  /// Shows the hierarchy stored on the device at once when there is one, then
  /// replaces it with the network copy. A launch no longer waits for the full
  /// network refresh (seconds on a slow connection) before the map and home
  /// can draw. While data is shown, a reload refreshes it in the background,
  /// and a failed refresh keeps the data on screen.
  Future<void> load(String farmId) async {
    final generation = ++_generation;
    final current = _state;
    var showing = current is FarmHierarchyReady &&
        current.snapshot.hierarchy.farmId == farmId;
    if (!showing) {
      _setState(const FarmHierarchyLoading());
      final cached = await _repository.loadCached(farmId);
      if (generation != _generation) return;
      if (cached != null) {
        _setState(FarmHierarchyReady(cached));
        showing = true;
      }
    }
    try {
      final fresh = await _repository.load(
        farmId,
        allowCachedFallback: !showing,
      );
      if (generation != _generation) return;
      _setState(FarmHierarchyReady(fresh));
    } catch (error) {
      if (generation != _generation || showing) return;
      _setState(FarmHierarchyFailure(error));
    }
  }

  void _setState(FarmHierarchyState state) {
    _state = state;
    notifyListeners();
  }
}
