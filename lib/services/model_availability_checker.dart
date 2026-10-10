import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;

class ModelCheckResult {
  const ModelCheckResult(this.success, this.message);
  final bool success;
  final String message;
}

class ModelAvailabilityChecker {
  ModelAvailabilityChecker({http.Client Function()? clientFactory})
    : clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() clientFactory;

  Future<ModelCheckResult> check({
    required String address,
    required String apiKey,
    required String model,
  }) async {
    final uri = Uri.tryParse(address.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return const ModelCheckResult(false, '检测失败：请输入有效的 API 基础地址（不含查询参数）。');
    }
    if (model.trim().isEmpty) {
      return const ModelCheckResult(false, '检测失败：请输入模型名称。');
    }
    final base = address.trim().replaceFirst(RegExp(r'/+$'), '');
    // The SDK always inserts /version; split the supplied API root accordingly.
    final path = Uri.parse(base).path;
    final hasVersion = RegExp(r'/v\d+$').hasMatch(path);
    final slash = base.lastIndexOf('/');
    final client = clientFactory();
    try {
      final sdk = OpenAIClient(
        apiKey: apiKey.trim(),
        baseUrl: hasVersion ? base.substring(0, slash) : base,
        version: hasVersion ? base.substring(slash + 1) : 'v1',
        requestsTimeOut: const Duration(seconds: 30),
        retryPolicy: const OpenAIRetryPolicy(maxAttempts: 1),
      );
      final response = await sdk.chat
          .create(
            model: model.trim(),
            messages: [
              OpenAIChatCompletionChoiceMessageModel.textContent(
                role: OpenAIChatMessageRole.user,
                text: 'Reply only: OK',
              ),
            ],
            maxTokens: 16,
            client: client,
          )
          .timeout(const Duration(seconds: 30));
      if (response.choices.isEmpty) {
        return const ModelCheckResult(false, '检测失败：接口返回了空的模型响应。');
      }
      return const ModelCheckResult(true, '检测成功：模型可调用。');
    } on RequestFailedException catch (e) {
      final detail = apiKey.trim().isEmpty
          ? e.message
          : e.message.replaceAll(apiKey.trim(), '[隐藏的 Key]');
      return ModelCheckResult(false, '检测失败（HTTP ${e.statusCode}）：$detail');
    } on TimeoutException {
      return const ModelCheckResult(false, '检测失败：请求超时（30 秒）。');
    } on http.ClientException {
      return const ModelCheckResult(
        false,
        '检测失败：无法连接接口。请检查网络、地址及浏览器跨域（CORS）限制。',
      );
    } catch (_) {
      return const ModelCheckResult(
        false,
        '检测失败：接口响应格式不符合 OpenAI Chat Completions 协议。',
      );
    } finally {
      client.close();
    }
  }
}
