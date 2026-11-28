import 'package:om_cryfio/features/auth/data/datasources/registration_api.dart';
import 'package:om_cryfio/features/auth/data/registration_crypto_service.dart';

final class RegistrationFlow {
  RegistrationFlow(
    this._api,{
      RegistrationCryptoService? cryptoService,
    }) : _cryptoService = cryptoService ?? RegistrationCryptoService();

    final RegistrationApi _api;
    final RegistrationCryptoService _cryptoService;

    Future<PendingRegistration> startRegistration({
      required String email,
      required String firstName,
      required String lastName,
      required String username,
    }){
      return _api.start(StartRegistrationRequest(
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: username
        ),
      );
    }
    Future<VerifiedRegistration> verifyEmail({
      required String accountId,
      required String code,
    }) {
      return _api.verifyEmail(
          accountId: accountId,
          code: code
      );
    }
    Future<CompletedRegistration> completeRegistration({
      required VerifiedRegistration verified,
      required String password
    }) async {
      final payload = await _cryptoService.createRegistrationPayload(
          email: verified.email,
          password: password,
          accountId: verified.accountId
      );
      return _api.uploadEncryptionMaterial(
          registrationToken: verified.registrationToken,
          encryptionMaterial: payload
      );
    }
}