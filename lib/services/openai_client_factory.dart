import 'package:dart_openai/dart_openai.dart';

/// Shared endpoint normalization and request policy for probes and runtime.
abstract final class OpenAIClientFactory {
  static OpenAIClient create({
    required String address,
    required String apiKey,
    required Duration timeout,
  }) {
    final root = address.trim().replaceFirst(RegExp(r'/+$'), '');
    final versioned = RegExp(r'/v\d+$').hasMatch(Uri.parse(root).path);
    final slash = root.lastIndexOf('/');
    return OpenAIClient(
      apiKey: apiKey.trim(),
      baseUrl: versioned ? root.substring(0, slash) : root,
      version: versioned ? root.substring(slash + 1) : 'v1',
      requestsTimeOut: timeout,
      retryPolicy: const OpenAIRetryPolicy(maxAttempts: 1),
    );
  }
}
