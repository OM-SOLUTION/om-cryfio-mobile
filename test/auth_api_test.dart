import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';

void main() {
  test('startSrpLogin sends the client public value', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/api/v1/auth/srp/start');
          expect(options.data, {
            'email': 'test@example.com',
            'clientPublicValue': 'test-public-value',
          });

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'challengeId': 'test-challenge',
                  'passwordKdfSalt': 'test-salt',
                  'passwordKdfMemoryKiB': 65536,
                  'passwordKdfIterations': 3,
                  'passwordKdfParallelism': 4,
                  'passwordKdfOutputBytes': 32,
                  'serverPublicValue': 'test-server-value',
                },
              },
            ),
          );
        },
      ),
    );

    final api = AuthApi(dio);

    final challenge = await api.startSrpLogin(
      email: 'test@example.com',
      clientPublicValue: 'test-public-value',
    );

    expect(challenge.challengeId, 'test-challenge');
    expect(challenge.passwordKdfMemoryKiB, 65536);
    expect(challenge.serverPublicValue, 'test-server-value');

    dio.close();
  });

  test('finishSrpLogin returns the proof and tokens', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/api/v1/auth/srp/finish');
          expect(options.data, {
            'challengeId': 'test-challenge',
            'clientProof': 'test-client-proof',
            'deviceName': 'Test device',
          });

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'serverProof': 'test-server-proof',
                  'accessToken': 'test-access-token',
                  'refreshToken': 'test-refresh-token',
                },
              },
            ),
          );
        },
      ),
    );

    final api = AuthApi(dio);

    final result = await api.finishSrpLogin(
      challengeId: 'test-challenge',
      clientProof: 'test-client-proof',
      deviceName: 'Test device',
    );

    expect(result.serverProof, 'test-server-proof');
    expect(result.accessToken, 'test-access-token');
    expect(result.refreshToken, 'test-refresh-token');

    dio.close();
  });
}