class Failure implements Exception {
  Failure({this.message = 'Unexpected error occurred.'});
  final String message;
}

/// A write the backend accepted but that changed zero rows — e.g. an
/// update/delete filtered out by row-level security. Must surface as an
/// error, never success.
class WriteBlockedFailure extends Failure {
  WriteBlockedFailure() : super(message: 'Write affected zero rows.');
}

class NoDataException implements Exception {
  NoDataException({this.message = 'No data available.'});
  final String message;
}
