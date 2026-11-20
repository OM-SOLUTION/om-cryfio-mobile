import 'package:dio/dio.dart';
import 'package:om_cryfio/features/auth/data/registration_api.dart';
import 'package:om_cryfio/features/auth/data/registration_crypto_service.dart';

const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

Future<void> main() async {
  final api = RegistrationApi(
    Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    ),
  );

  print('========== REGISTRATION DEMO ==========');
  print('Backend URL: $baseUrl');

  // Step 1: create the pending account.
  final pending = await api.start(
    const StartRegistrationRequest(
      email: 'mossab.test@example.com',
      firstName: 'Mossab',
      lastName: 'Milha',
      username: 'mossab_test_01',
    ),
  );

  print('\n1. Pending registration created');
  print('Account ID: ${pending.accountId}');
  print('Status: ${pending.status}');
  print('Check ${pending.email} for the verification code.');

  // Step 2: copy the code that arrived by email here.
  const emailCode = 'REPLACE_WITH_EMAIL_CODE';

  if (emailCode == 'REPLACE_WITH_EMAIL_CODE') {
    throw StateError(
      'Put the email verification code into emailCode, then run again.',
    );
  }

  final verified = await api.verifyEmail(
    accountId: pending.accountId,
    code: emailCode,
  );

  print('\n2. Email verified');
  print('Account ID: ${verified.accountId}');
  print('Status: ${verified.status}');
  print('Registration token received: yes');

  // Step 3: only now create the identity and encrypted private-key backup.
  //
  // This password is only a local test password.
  // The backend never receives it.
  const password = 'demo-password-only-for-local-test';

  final crypto = RegistrationCryptoService();
  final prepared = await crypto.prepare(
    password: password,
    accountId: verified.accountId,
  );

  try {
    // Step 4: upload only public/encrypted crypto material.
    // No plaintext password or private key is in this request.
    final completed = await api.uploadEncryptionMaterial(
      registrationToken: verified.registrationToken,
      encryptionMaterial: prepared.payload.toJson(),
    );

    print('\n3. Encryption material uploaded');
    print('Account ID: ${completed.accountId}');
    print('Final status: ${completed.status}');
    print('Activated at: ${completed.activatedAt}');
  } finally {
    // Best-effort removal of the private-key bytes from this object.
    prepared.destroy();
  }

  print('\n========== REGISTRATION COMPLETE ==========');
}