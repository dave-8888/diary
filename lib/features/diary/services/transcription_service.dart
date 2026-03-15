import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService();
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
  static const String _apiUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  Future<TranscriptionResult> transcribe(String audioPath) async {
    if (_apiKey.isEmpty) {
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
      ..headers['Authorization'] = 'Bearer $_apiKey'
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
