import 'dart:async';

import 'package:dio/dio.dart';

import '../models/api_models.dart';
import 'api_client.dart';

Future<AIJobOut> waitForJob(String jobId, {CancelToken? cancelToken}) =>
    JobPoller().waitForJob(jobId, cancelToken: cancelToken);

class JobPoller {
  static const _pollInterval = Duration(seconds: 3);
  static const _timeout = Duration(minutes: 3);

  Future<AIJobOut> waitForJob(String jobId, {CancelToken? cancelToken}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < _timeout) {
      if (cancelToken?.isCancelled ?? false) {
        throw DioException(
          requestOptions: RequestOptions(path: 'ai-jobs/$jobId'),
          type: DioExceptionType.cancel,
        );
      }
      final json = await ApiClient.instance.getJson(
        'ai-jobs/${Uri.encodeComponent(jobId)}',
        cancelToken: cancelToken,
      );
      if (stopwatch.elapsed >= _timeout) {
        throw const ApiException('İşlem zaman aşımına uğradı.');
      }

      final job = AIJobOut.fromJson(json);
      if (job.status == 'done') {
        return job;
      }
      if (job.status == 'failed') {
        throw ApiException(_failureMessage(job.errorCode));
      }

      final remaining = _timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        break;
      }
      final delay = remaining < _pollInterval ? remaining : _pollInterval;
      final cancelSignal = cancelToken?.whenCancel.then<void>((_) {});
      if (cancelSignal == null) {
        await Future<void>.delayed(delay);
      } else {
        await Future.any<void>([Future<void>.delayed(delay), cancelSignal]);
      }
    }
    throw const ApiException('İşlem zaman aşımına uğradı.');
  }

  String _failureMessage(String? errorCode) => switch (errorCode) {
    'n8n_unreachable' =>
      'AI servisine ulaşılamıyor. Lütfen daha sonra tekrar deneyin.',
    'n8n_timeout' => 'AI servisi yanıt vermek için zaman aşımına uğradı.',
    'n8n_bad_response' => 'AI servisinden geçersiz bir yanıt alındı.',
    'n8n_error' => 'AI işlemi sırasında bir hata oluştu.',
    'timeout' => 'İşlem zaman aşımına uğradı.',
    'too_large' => 'Gönderilen içerik izin verilen boyutu aşıyor.',
    _ => 'AI işlemi tamamlanamadı.',
  };
}
