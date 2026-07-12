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

  Future<void> load(String farmId) async {
    _setState(const FarmHierarchyLoading());
    try {
      _setState(FarmHierarchyReady(await _repository.load(farmId)));
    } catch (error) {
      _setState(FarmHierarchyFailure(error));
    }
  }

  void _setState(FarmHierarchyState state) {
    _state = state;
    notifyListeners();
  }
}
