import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService();
});

class TranscriptionResult {
  const TranscriptionResult({
    required this.ok,
    required this.message,
    this.text,
  });

  final bool ok;
  final String message;
  final String? text;
}

class TranscriptionService {
  static const String _apiUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  Future<TranscriptionResult> transcribe(String audioPath) async {
    if (_apiKey.isEmpty) {
      return const TranscriptionResult(
        ok: false,
        message: 'OPENAI_API_KEY not set. Skipping transcription.',
      );
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      return TranscriptionResult(
        ok: false,
        message: 'Audio file was not found: $audioPath',
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
        message:
            'Transcription request failed (${streamedResponse.statusCode}).',
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final text = decoded['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        return TranscriptionResult(
          ok: true,
          message: 'Transcription completed.',
          text: text.trim(),
        );
      }
    }

    return const TranscriptionResult(
      ok: false,
      message: 'No transcription text returned from API.',
    );
  }
}
