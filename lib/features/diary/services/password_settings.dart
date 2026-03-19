import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final passwordSettingsStorageProvider = Provider<PasswordSettingsStorage>((
  ref,
) {
  return PasswordSettingsStorage();
});

final passwordSettingsControllerProvider =
    AsyncNotifierProvider<PasswordSettingsController, PasswordSettingsState>(
  PasswordSettingsController.new,
);

final startupUnlockSessionControllerProvider =
    AsyncNotifierProvider<StartupUnlockSessionController, bool>(
  StartupUnlockSessionController.new,
);

class PasswordSettingsState {
  const PasswordSettingsState({
    required this.enabled,
    required this.salt,
    required this.passwordHash,
  });

  const PasswordSettingsState.disabled()
      : enabled = false,
        salt = '',
        passwordHash = '';

  final bool enabled;
  final String salt;
  final String passwordHash;

  bool get hasPassword =>
      enabled && salt.trim().isNotEmpty && passwordHash.trim().isNotEmpty;
}

class PasswordHashData {
  const PasswordHashData({
    required this.salt,
    required this.passwordHash,
  });

  final String salt;
  final String passwordHash;
}

enum PasswordSettingsFailure {
  invalidCurrentPassword,
}

class PasswordSettingsException implements Exception {
  const PasswordSettingsException(this.failure);

  final PasswordSettingsFailure failure;

  @override
  String toString() {
    return 'PasswordSettingsException($failure)';
  }
}

bool isValidPassword(String value) {
  return value.trim().isNotEmpty;
}

PasswordHashData hashPassword(
  String password, {
  String? salt,
}) {
  final resolvedSalt = salt ?? generatePasswordSalt();
  final digest =
      sha256.convert(utf8.encode('$resolvedSalt:$password')).toString();
  return PasswordHashData(
    salt: resolvedSalt,
    passwordHash: digest,
  );
}

bool verifyPassword(
  String password,
  PasswordSettingsState settings,
) {
  if (!settings.hasPassword) {
    return false;
  }

  final hashed = hashPassword(
    password,
    salt: settings.salt,
  );
  return hashed.passwordHash == settings.passwordHash;
}

String generatePasswordSalt([
  Random? random,
]) {
  final secureRandom = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => secureRandom.nextInt(256));
  return base64UrlEncode(bytes);
}

class PasswordSettingsStorage {
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
    return File(p.join(settingsDir.path, 'password_settings.json'));
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

class PasswordSettingsController extends AsyncNotifier<PasswordSettingsState> {
  PasswordSettingsStorage get _storage =>
      ref.read(passwordSettingsStorageProvider);

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

  Future<void> disablePassword() async {
    final previous = state.valueOrNull ?? await _storage.read();
    const next = PasswordSettingsState.disabled();
    state = const AsyncData(next);

    try {
      await _storage.write(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class StartupUnlockSessionController extends AsyncNotifier<bool> {
  PasswordSettingsStorage get _storage =>
      ref.read(passwordSettingsStorageProvider);

  @override
  Future<bool> build() async {
    final settings = await _storage.read();
    return !settings.hasPassword;
  }

  Future<bool> unlock(String password) async {
    final settings = await _storage.read();
    if (!settings.hasPassword) {
      state = const AsyncData(true);
      return true;
    }

    final isUnlocked = verifyPassword(password, settings);
    state = AsyncData(isUnlocked);
    return isUnlocked;
  }

  void keepUnlocked() {
    state = const AsyncData(true);
  }
}
