class ModelCheckResult {
  const ModelCheckResult(this.success, this.message);
  final bool success;
  final String message;
}

abstract interface class ApiChecker {
  Future<ModelCheckResult> checkApi({
    required String address,
    required String apiKey,
  });
  Future<ModelCheckResult> check({
    required String address,
    required String apiKey,
    required String model,
  });
}
