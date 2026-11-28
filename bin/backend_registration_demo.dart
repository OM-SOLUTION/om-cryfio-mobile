import 'dart:io';

import 'package:dio/dio.dart';
import 'package:om_cryfio/features/auth/application/registration_flow.dart';
import 'package:om_cryfio/features/auth/data/datasources/registration_api.dart';

const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  final flow = RegistrationFlow(RegistrationApi(dio));

  print('========== REGISTRATION TEST ==========');
  print('Backend: $baseUrl');
  print('Use a disposable test account.\n');

  try {
    final email = ask('Email');
    final firstName = ask('First name');
    final lastName = ask('Last name');
    final username = ask('Username');

    print('\n1. Creating pending registration...');

    final pending = await flow.startRegistration(
      email: email,
      firstName: firstName,
      lastName: lastName,
      username: username,
    );

    print('Account ID: ${pending.accountId}');
    print('Status: ${pending.status}');

    print('\n2. Check ${pending.email} for the email code.');
    final code = ask('Email verification code');

    final verified = await flow.verifyEmail(
      accountId: pending.accountId,
      code: code,
    );

    print('Email verified. Status: ${verified.status}');

    print('\n3. Preparing and uploading encryption material...');
    print('The password is visible as you type; use a test password.');
    final password = ask('Test password');

    final completed = await flow.completeRegistration(
      verified: verified,
      password: password,
    );

    print('\n========== BACKEND RESPONSE ==========');
    print('Account ID: ${completed.accountId}');
    print('Status: ${completed.status}');
    print('Activated at: ${completed.activatedAt}');
  } on RegistrationApiException catch (error) {
    print('\nRegistration API error: ${error.message}');
  } catch (error) {
    print('\nRegistration test failed: $error');
  } finally {
    dio.close();
  }
}

String ask(String label) {
  stdout.write('$label: ');
  final value = stdin.readLineSync();

  if (value == null || value.isEmpty) {
    throw StateError('$label cannot be empty.');
  }
  return value;
}