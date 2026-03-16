import 'dart:convert';
import 'dart:io';

import 'package:diary_mvp/features/diary/services/transcription_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService(ref);
});

enum TranscriptionFailure {
  apiKeyMissing,
  fileNotFound,
  requestFailed,
  emptyResponse,
}

class TranscriptionResult {
  const TranscriptionResult({
    required this.ok,
    this.text,
    this.failure,
    this.statusCode,
  });

  final bool ok;
  final String? text;
  final TranscriptionFailure? failure;
  final int? statusCode;
}

class TranscriptionService {
  TranscriptionService(this._ref);

  static const String _apiUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  final Ref _ref;

  Future<TranscriptionResult> transcribe(String audioPath) async {
    final configuredApiKey =
        _ref.read(transcriptionApiKeyControllerProvider).valueOrNull;
    final apiKey = (configuredApiKey?.trim().isNotEmpty == true)
        ? configuredApiKey!.trim()
        : transcriptionEnvironmentApiKey;

    if (apiKey.isEmpty) {
      return const TranscriptionResult(
        ok: false,
        failure: TranscriptionFailure.apiKeyMissing,
      );
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      return const TranscriptionResult(
        ok: false,
        failure: TranscriptionFailure.fileNotFound,
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['response_format'] = 'json'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 400) {
      return TranscriptionResult(
        ok: false,
        failure: TranscriptionFailure.requestFailed,
        statusCode: streamedResponse.statusCode,
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final text = decoded['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        return TranscriptionResult(
          ok: true,
          text: text.trim(),
        );
      }
    }

    return const TranscriptionResult(
      ok: false,
      failure: TranscriptionFailure.emptyResponse,
    );
  }
}
