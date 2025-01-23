class ValidationError implements Exception {
  final String message;
  final String? field;

  ValidationError(this.message, [this.field]);

  @override
  String toString() => field != null 
    ? 'ValidationError: $message (field: $field)'
    : 'ValidationError: $message';
}
