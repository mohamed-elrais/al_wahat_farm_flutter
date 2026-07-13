enum OperationFailureKind {
  invalidInput,
  notFound,
  authorization,
  offline,
  conflict,
  unexpected,
}

class OperationFailure implements Exception {
  const OperationFailure(this.kind, this.message, {this.cause});

  final OperationFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'OperationFailure(${kind.name}): $message';
}
