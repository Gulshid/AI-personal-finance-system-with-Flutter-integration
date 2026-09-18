/// Thrown by [FinanceAiService] for any failure — network, timeout, HTTP
/// error, or unexpected shape — so every screen can catch one exception
/// type and show [message] directly instead of parsing raw exceptions.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
