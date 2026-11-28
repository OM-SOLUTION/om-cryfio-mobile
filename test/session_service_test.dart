import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/application/login_flow.dart';
import 'package:om_cryfio/features/auth/application/session_service.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';
import 'package:om_cryfio/features/auth/data/services/token_storage.dart';

final class FakeTokenStorage implements RefreshTokenStore {
  FakeTokenStorage(this.refreshToken);

  String? refreshToken;
  bool failWrites = false;
  
  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    if(failWrites){
      throw StateError('Secure storage failed.');
    }
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> deleteRefreshToken() async {
    refreshToken = null;
  }
}

void main() {
  test('concurrent refreshes share one request and store rotated token',
          () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
        final storage = FakeTokenStorage('old-refresh-token');

        var requestCount = 0;
        final requestStarted = Completer<void>();
        final releaseResponse = Completer<void>();

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              expect(options.path, '/api/v1/auth/refresh');
              expect(options.data, {
                'refreshToken': 'old-refresh-token',
              });

              requestCount++;
              requestStarted.complete();

              // Keep the first request pending while the second caller starts.
              await releaseResponse.future;

              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'accessToken': 'new-access-token',
                      'refreshToken': 'new-refresh-token',
                    },
                  },
                ),
              );
            },
          ),
        );

        final api = AuthApi(dio);
        final session = SessionService(
          LoginFlow(api),
          storage,
          api,
        );

        final first = session.refreshSession();

        await requestStarted.future;

        final second = session.refreshSession();
        releaseResponse.complete();

        await Future.wait([first, second]);

        expect(requestCount, 1);
        expect(session.accessToken, 'new-access-token');
        expect(storage.refreshToken, 'new-refresh-token');

        dio.close();
      });
  test('clears the access token if rotated token storage fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final storage = FakeTokenStorage('initial-refresh-token');

    var requestCount = 0;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/v1/auth/refresh');

          requestCount++;

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'accessToken': 'access-$requestCount',
                  'refreshToken': 'refresh-$requestCount',
                },
              },
            ),
          );
        },
      ),
    );

    final api = AuthApi(dio);
    final session = SessionService(
      LoginFlow(api),
      storage,
      api,
    );

    // First refresh succeeds and gives the service an access token.
    await session.refreshSession();

    expect(session.accessToken, 'access-1');
    expect(storage.refreshToken, 'refresh-1');

    // The backend returns another pair, but saving it fails.
    storage.failWrites = true;

    await expectLater(
      session.refreshSession(),
      throwsStateError,
    );

    expect(requestCount, 2);
    expect(session.accessToken, isNull);

    // The fake store still contains the previous value.
    expect(storage.refreshToken, 'refresh-1');

    dio.close();
  });
}