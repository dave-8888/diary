import 'package:diary_mvp/features/diary/services/hidden_diary_settings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hidden diary password controller can save and verify a password',
      () async {
    final storage = InMemoryHiddenDiaryPasswordSettingsStorage();
    final container = ProviderContainer(
      overrides: [
        hiddenDiaryPasswordSettingsStorageProvider.overrideWith(
          (ref) => storage,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(hiddenDiaryPasswordSettingsControllerProvider.future);
    await container
        .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
        .setPassword('vault-123');

    final stored = await storage.read();
    expect(stored.hasPassword, isTrue);
    expect(verifyPassword('vault-123', stored), isTrue);
    expect(
      await container
          .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
          .verifyInput('wrong-password'),
      isFalse,
    );
    expect(
      await container
          .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
          .verifyInput('vault-123'),
      isTrue,
    );
  });

  test('hidden diary password controller requires current password to change',
      () async {
    final hashed = hashPassword('vault-123');
    final storage = InMemoryHiddenDiaryPasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        hiddenDiaryPasswordSettingsStorageProvider.overrideWith(
          (ref) => storage,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(hiddenDiaryPasswordSettingsControllerProvider.future);

    await expectLater(
      container
          .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
          .changePassword(
            currentPassword: 'wrong-password',
            newPassword: 'next-456',
          ),
      throwsA(isA<PasswordSettingsException>()),
    );

    await container
        .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
        .changePassword(
          currentPassword: 'vault-123',
          newPassword: 'next-456',
        );

    final stored = await storage.read();
    expect(verifyPassword('next-456', stored), isTrue);
  });
}

class InMemoryHiddenDiaryPasswordSettingsStorage
    extends HiddenDiaryPasswordSettingsStorage {
  InMemoryHiddenDiaryPasswordSettingsStorage([
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
