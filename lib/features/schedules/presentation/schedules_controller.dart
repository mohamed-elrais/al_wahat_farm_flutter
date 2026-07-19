import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/schedules/data/schedule_repository.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:flutter/foundation.dart';

enum SchedulesStatus { idle, loading, ready, failure }

/// Loads the farm's operation plans and runs manager mutations. Schedules are
/// a manager-only, online-first surface (workers only ever see the generated
/// tasks).
class SchedulesController extends ChangeNotifier {
  SchedulesController({
    required ScheduleRepository repository,
    required this.farmId,
  }) : _repository = repository;

  final ScheduleRepository _repository;
  final String farmId;

  SchedulesStatus _status = SchedulesStatus.idle;
  List<OperationPlan> _plans = const <OperationPlan>[];
  Object? _error;
  bool _busy = false;
  String Function(AppLocalizations)? _message;

  SchedulesStatus get status => _status;
  List<OperationPlan> get plans => _plans;
  Object? get error => _error;
  bool get isBusy => _busy;
  String Function(AppLocalizations)? get message => _message;

  OperationPlan? planById(String id) {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  Future<void> load() async {
    _status = SchedulesStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _plans = await _repository.listPlans(farmId);
      _status = SchedulesStatus.ready;
    } catch (error) {
      _error = error;
      _status = SchedulesStatus.failure;
    }
    notifyListeners();
  }

  Future<String?> createPlan(OperationPlanDraft draft) => _mutate(() async {
        final id = await _repository.createPlan(draft);
        _message = (l10n) => l10n.scheduleMsgCreated;
        return id;
      });

  Future<String?> setStatus(String planId, OperationPlanStatus status) =>
      _mutate(() async {
        await _repository.updatePlan(planId, status: status);
        _message = (l10n) => l10n.scheduleMsgUpdated;
        return planId;
      });

  Future<List<PlanInventoryCheck>> checkInventory(String planId) =>
      _repository.checkInventory(planId);

  Future<int?> generateNow() async {
    if (_busy) return null;
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      final count = await _repository.generateNow(farmId);
      return count;
    } catch (error) {
      _message = error is OperationFailure
          ? ((_) => error.message)
          : ((l10n) => l10n.scheduleErrGeneric);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> _mutate(Future<String> Function() action) async {
    if (_busy) return null;
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      final result = await action();
      await load();
      return result;
    } catch (error) {
      _message = error is OperationFailure
          ? ((_) => error.message)
          : ((l10n) => l10n.scheduleErrGeneric);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
