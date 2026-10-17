import 'dart:async';
import 'package:rolechat/application/apis/ports/api_checker.dart';
import 'package:rolechat/infrastructure/ai/openai_client_factory.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;

class ModelAvailabilityChecker implements ApiChecker {
  ModelAvailabilityChecker({http.Client Function()? clientFactory})
    : clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() clientFactory;

  @override
  Future<ModelCheckResult> checkApi({
    required String address,
    required String apiKey,
  }) => _check(address: address, apiKey: apiKey);

  @override
  Future<ModelCheckResult> check({
    required String address,
    required String apiKey,
    required String model,
  }) => _check(address: address, apiKey: apiKey, model: model);

  Future<ModelCheckResult> _check({
    required String address,
    required String apiKey,
    String? model,
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
    if (model != null && model.trim().isEmpty) {
      return const ModelCheckResult(false, '检测失败：请输入模型名称。');
    }
    final client = clientFactory();
    try {
      final sdk = OpenAIClientFactory.create(
        address: address,
        apiKey: apiKey.trim(),
        timeout: const Duration(seconds: 30),
      );
      if (model == null) {
        await sdk.model
            .list(client: client)
            .timeout(const Duration(seconds: 30));
        return const ModelCheckResult(true, '检查成功：接口与 API Key 可访问模型列表。');
      }
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
      return const ModelCheckResult(false, '检测失败：接口响应格式不符合 OpenAI 协议。');
    } finally {
      client.close();
    }
  }
}
