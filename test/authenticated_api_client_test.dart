import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/core/network/authenticated_api_client.dart';

/// Records requests and returns an empty successful JSON response.
/// No real network request is made.
final class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
      ) async {
    requests.add(options);

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('attaches the current access token to a backend request', () async {
    var token = 'first-token';
    final adapter = RecordingAdapter();

    final dio = createAuthenticatedApiClient(
      baseUrl: 'http://localhost:8080',
      getAccessToken: () => token,
    );

    dio.httpClientAdapter = adapter;

    await dio.get<dynamic>('/api/v1/resources');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer first-token',
    );

    // The client reads the current token for each request.
    token = 'rotated-token';

    await dio.get<dynamic>('/api/v1/resources');

    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer rotated-token',
    );

    dio.close();
  });

  test('rejects a request when there is no access token', () async {
    final adapter = RecordingAdapter();

    final dio = createAuthenticatedApiClient(
      baseUrl: 'http://localhost:8080',
      getAccessToken: () => null,
    );

    dio.httpClientAdapter = adapter;

    await expectLater(
      dio.get<dynamic>('/api/v1/resources'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests, isEmpty);

    dio.close();
  });

  test('does not send a token to another origin', () async {
    final adapter = RecordingAdapter();

    final dio = createAuthenticatedApiClient(
      baseUrl: 'http://localhost:8080',
      getAccessToken: () => 'test-token',
    );

    dio.httpClientAdapter = adapter;

    await expectLater(
      dio.get<dynamic>('https://other.example/api'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests, isEmpty);

    dio.close();
  });
}