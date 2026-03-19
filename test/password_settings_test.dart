import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password hashing verifies correct and incorrect passwords', () {
    final hashed = hashPassword('hello-123');
    final settings = PasswordSettingsState(
      enabled: true,
      salt: hashed.salt,
      passwordHash: hashed.passwordHash,
    );

    expect(verifyPassword('hello-123', settings), isTrue);
    expect(verifyPassword('wrong-password', settings), isFalse);
    expect(const PasswordSettingsState.disabled().hasPassword, isFalse);
  });

  test('startup unlock session is unlocked when no passcode exists', () async {
    final container = ProviderContainer(
      overrides: [
        passwordSettingsStorageProvider.overrideWith(
          (ref) => InMemoryPasswordSettingsStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(startupUnlockSessionControllerProvider.future),
      isTrue,
    );
  });

  test('startup unlock session locks until the correct password is entered',
      () async {
    final hashed = hashPassword('hello-123');
    final storage = InMemoryPasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        passwordSettingsStorageProvider.overrideWith((ref) => storage),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(startupUnlockSessionControllerProvider.future),
      isFalse,
    );

    expect(
      await container
          .read(startupUnlockSessionControllerProvider.notifier)
          .unlock('wrong-password'),
      isFalse,
    );
    expect(
      container.read(startupUnlockSessionControllerProvider).valueOrNull,
      isFalse,
    );

    expect(
      await container
          .read(startupUnlockSessionControllerProvider.notifier)
          .unlock('hello-123'),
      isTrue,
    );
    expect(
      container.read(startupUnlockSessionControllerProvider).valueOrNull,
      isTrue,
    );
  });

  test('disabling the passcode clears the stored password state', () async {
    final hashed = hashPassword('hello-123');
    final storage = InMemoryPasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        passwordSettingsStorageProvider.overrideWith((ref) => storage),
      ],
    );
    addTearDown(container.dispose);

    await container.read(passwordSettingsControllerProvider.future);
    await container
        .read(passwordSettingsControllerProvider.notifier)
        .disablePassword();
    container
        .read(startupUnlockSessionControllerProvider.notifier)
        .keepUnlocked();

    expect((await storage.read()).hasPassword, isFalse);
    expect(container.read(startupUnlockSessionControllerProvider).valueOrNull,
        isTrue);
  });
}

class InMemoryPasswordSettingsStorage extends PasswordSettingsStorage {
  InMemoryPasswordSettingsStorage([
    PasswordSettingsState? value,
  ]) : _value = value ?? const PasswordSettingsState.disabled();

  PasswordSettingsState _value;

  @override
  Future<PasswordSettingsState> read() async => _value;

  @override
  Future<void> write(PasswordSettingsState settings) async {
    _value = settings;
  }
}
