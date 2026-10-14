abstract class Failure {
  Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}