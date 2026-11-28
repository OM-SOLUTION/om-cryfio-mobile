import 'dart:io';

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

  print('==============================================');
  print('        CRYFIO REGISTRATION TEST');
  print('==============================================');
  print('Backend: $baseUrl\n');

  try {
    // ---------- Step 1: create pending registration ----------
    print('STEP 1 — Create registration');

    final email = _ask('Email');
    final firstName = _ask('First name');
    final lastName = _ask('Last name');
    final username = _ask('Username');

    final pending = await api.start(
      StartRegistrationRequest(
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
      ),
    );

    print('\nRegistration created successfully.');
    print('Account ID: ${pending.accountId}');
    print('Email: ${pending.email}');
    print('Status: ${pending.status}');

    // ---------- Step 2: verify email ----------
    print('\nSTEP 2 — Verify email');
    print('Check $email for the verification code.');

    final code = _ask('Email verification code');

    final verified = await api.verifyEmail(
      accountId: pending.accountId,
      code: code,
    );

    print('\nEmail verified successfully.');
    print('Account ID: ${verified.accountId}');
    print('Status: ${verified.status}');
    print('Temporary registration token received.');

    // ---------- Step 3: create crypto material locally ----------
    print('\nSTEP 3 — Create local encryption identity');
    print('This password stays on this device. It is never sent to the backend.');

    final password = _ask('Password for this local test');

    final crypto = RegistrationCryptoService();
    final prepared = await crypto.prepare(
      password: password,
      accountId: verified.accountId,
    );

    try {
      print('X25519 identity generated locally.');
      print('Private key encrypted locally with Argon2id + AES-256-GCM.');
      print('Plaintext private key will NOT be uploaded.');

      // ---------- Step 4: upload only safe crypto payload ----------
      print('\nSTEP 4 — Upload encryption material');

      final completed = await api.uploadEncryptionMaterial(
        registrationToken: verified.registrationToken,
        encryptionMaterial: prepared.payload.toJson(),
      );

      print('\n==============================================');
      print('       REGISTRATION COMPLETED');
      print('==============================================');
      print('Account ID: ${completed.accountId}');
      print('Final status: ${completed.status}');
      print('Activated at: ${completed.activatedAt}');
    } finally {
      // Best effort: overwrite the in-memory private-key bytes.
      prepared.destroy();
    }
  } on RegistrationApiException catch (error) {
    print('\nBACKEND ERROR');
    print(error.message);
  } on StateError catch (error) {
    print('\nINPUT ERROR');
    print(error.message);
  } catch (error, stackTrace) {
    print('\nUNEXPECTED ERROR');
    print(error);
    print(stackTrace);
  }
}

String _ask(String label) {
  stdout.write('$label: ');

  final value = stdin.readLineSync()?.trim() ?? '';

  if (value.isEmpty) {
    throw StateError('$label cannot be empty.');
  }

  return value;
}