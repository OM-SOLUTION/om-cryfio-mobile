import 'dart:io';

import 'package:dio/dio.dart';
import 'package:om_cryfio/features/auth/application/login_flow.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';

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

  final loginFlow = LoginFlow(AuthApi(dio));

  print('========== SRP LOGIN TEST ==========');
  print('Backend: $baseUrl');
  print('Use the disposable account you registered.\n');

  try {
    final email = ask('Email');

    print('The password is visible as you type; use your test password.');
    final password = ask('Test password');

    print('\nStarting SRP login...');

    final tokens = await loginFlow.login(
      email: email,
      password: password,
      deviceName: 'Terminal test',
    );

    // Do not print or save either token.
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      throw StateError('Backend returned an empty token.');
    }

    print('\nLogin successful.');
    print('The server proof was verified.');
    print('Access token received: yes');
    print('Refresh token received: yes');
  } on AuthApiException catch (error) {
    print('\nAuthentication API error: ${error.message}');
  } on LoginFlowException catch (error) {
    print('\nLogin error: ${error.message}');
  } catch (error) {
    print('\nLogin test failed: $error');
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