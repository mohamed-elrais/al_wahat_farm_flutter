import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:flutter/foundation.dart';

sealed class AuthBootstrapState {
  const AuthBootstrapState();
}

class AuthBootstrapIdle extends AuthBootstrapState {
  const AuthBootstrapIdle();
}

class AuthBootstrapLoading extends AuthBootstrapState {
  const AuthBootstrapLoading();
}

class AuthBootstrapReady extends AuthBootstrapState {
  const AuthBootstrapReady(this.context);

  final OperationalContext context;
}

class AuthBootstrapBlocked extends AuthBootstrapState {
  const AuthBootstrapBlocked(this.reason);

  final BootstrapBlockReason reason;
}

class AuthBootstrapFailure extends AuthBootstrapState {
  const AuthBootstrapFailure(this.error);

  final Object error;
}

class AuthBootstrapController extends ChangeNotifier {
  AuthBootstrapController(this._repository);

  final OperationalContextRepository _repository;
  AuthBootstrapState _state = const AuthBootstrapIdle();

  AuthBootstrapState get state => _state;

  Future<void> load(String userId) async {
    _setState(const AuthBootstrapLoading());
    try {
      _setState(AuthBootstrapReady(await _repository.load(userId)));
    } on BootstrapBlockedException catch (error) {
      _setState(AuthBootstrapBlocked(error.reason));
    } catch (error) {
      _setState(AuthBootstrapFailure(error));
    }
  }

  void _setState(AuthBootstrapState next) {
    _state = next;
    notifyListeners();
  }
}
