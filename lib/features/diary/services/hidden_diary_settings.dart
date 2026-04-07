import 'dart:convert';
import 'dart:io';

import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final hiddenDiaryPasswordSettingsStorageProvider =
    Provider<HiddenDiaryPasswordSettingsStorage>((ref) {
  return HiddenDiaryPasswordSettingsStorage();
});

final hiddenDiaryPasswordSettingsControllerProvider = AsyncNotifierProvider<
    HiddenDiaryPasswordSettingsController, PasswordSettingsState>(
  HiddenDiaryPasswordSettingsController.new,
);

final showHiddenDiariesProvider = StateProvider<bool>((ref) => false);

class HiddenDiaryPasswordSettingsStorage {
  Future<PasswordSettingsState> read() async {
    final raw = await _readRaw();
    final enabled = raw['enabled'];
    if (enabled is! bool || !enabled) {
      return const PasswordSettingsState.disabled();
    }

    final salt = raw['salt'];
    final passwordHash = raw['password_hash'];
    if (salt is! String || passwordHash is! String) {
      return const PasswordSettingsState.disabled();
    }

    return PasswordSettingsState(
      enabled: true,
      salt: salt.trim(),
      passwordHash: passwordHash.trim(),
    );
  }

  Future<void> write(PasswordSettingsState settings) async {
    final file = await _settingsFile();
    final raw = <String, dynamic>{
      'enabled': settings.hasPassword,
    };

    if (settings.hasPassword) {
      raw['salt'] = settings.salt;
      raw['password_hash'] = settings.passwordHash;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(raw),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(
        p.join(settingsDir.path, 'hidden_diary_password_settings.json'));
  }

  Future<Map<String, dynamic>> _readRaw() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw);
      }
    } on FormatException {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }
}

class HiddenDiaryPasswordSettingsController
    extends AsyncNotifier<PasswordSettingsState> {
  HiddenDiaryPasswordSettingsStorage get _storage =>
      ref.read(hiddenDiaryPasswordSettingsStorageProvider);

  @override
  Future<PasswordSettingsState> build() {
    return _storage.read();
  }

  Future<void> setPassword(String password) async {
    final previous = state.valueOrNull ?? await _storage.read();
    final hashed = hashPassword(password);
    final next = PasswordSettingsState(
      enabled: true,
      salt: hashed.salt,
      passwordHash: hashed.passwordHash,
    );
    state = AsyncData(next);

    try {
      await _storage.write(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final previous = state.valueOrNull ?? await _storage.read();
    if (previous.hasPassword && !verifyPassword(currentPassword, previous)) {
      throw const PasswordSettingsException(
        PasswordSettingsFailure.invalidCurrentPassword,
      );
    }

    final hashed = hashPassword(newPassword);
    final next = PasswordSettingsState(
      enabled: true,
      salt: hashed.salt,
      passwordHash: hashed.passwordHash,
    );
    state = AsyncData(next);

    try {
      await _storage.write(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<bool> verifyInput(String password) async {
    final settings = state.valueOrNull ?? await _storage.read();
    return verifyPassword(password, settings);
  }
}
