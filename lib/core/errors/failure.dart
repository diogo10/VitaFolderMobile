class Failure implements Exception {
  Failure({this.message = 'Unexpected error occurred.'});
  final String message;
}

class NoDataException implements Exception {
  NoDataException({this.message = 'No data available.'});
  final String message;
}
