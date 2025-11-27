class InvalidTrueTypeFontException implements Exception {
  final String message;
  InvalidTrueTypeFontException(this.message);
  @override
  String toString() => 'InvalidTrueTypeFontException: $message';
}
