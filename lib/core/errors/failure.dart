class Failure implements Exception {
  final String message;
  Failure({this.message = 'Unexpected error occurred.'});
}

class NoDataException implements Exception {
  final String message;
  NoDataException({this.message = 'No data available.'});
}
