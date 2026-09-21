import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../core/config/google_config.dart';
import '../core/errors/backup_exception.dart';

/// Picks the Google account and hands out Drive-authorised HTTP clients.
///
/// Only the hidden `drive.appdata` scope is requested: the app can see its
/// own backup files and nothing else in the user's Drive.
class GoogleAccountService {
  GoogleAccountService({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  static const scopes = [drive.DriveApi.driveAppdataScope];

  final GoogleSignIn _signIn;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() => _initialization ??= _signIn.initialize(
    clientId: Platform.isIOS ? GoogleConfig.iosClientIdOrNull : null,
    serverClientId: GoogleConfig.serverClientIdOrNull,
  );

  /// Shows the device account picker, then the Drive consent screen.
  /// Returns the chosen account's email.
  Future<String> pickAccount() async {
    try {
      await _ensureInitialized();
      final account = await _signIn.authenticate(scopeHint: scopes);
      await account.authorizationClient.authorizeScopes(scopes);
      return account.email;
    } catch (error) {
      throw BackupException.from(error);
    }
  }

  /// A Drive client for [email].
  ///
  /// With [interactive] false (background work) this never shows UI and
  /// throws [BackupFailure.notAuthorized] when consent is missing.
  Future<gapis.AuthClient> clientFor(
    String email, {
    required bool interactive,
  }) async {
    try {
      await _ensureInitialized();
      // The app-facing API only authorises by email via a signed-in account
      // object, which needs an Activity. The platform call works headless.
      final tokens = await GoogleSignInPlatform.instance
          .clientAuthorizationTokensForScopes(
            ClientAuthorizationTokensForScopesParameters(
              request: AuthorizationRequestDetails(
                scopes: scopes,
                userId: null,
                email: email,
                promptIfUnauthorized: interactive,
              ),
            ),
          );
      if (tokens == null) {
        throw const BackupException(BackupFailure.notAuthorized);
      }
      return GoogleSignInClientAuthorization(
        accessToken: tokens.accessToken,
      ).authClient(scopes: scopes);
    } catch (error) {
      throw BackupException.from(error);
    }
  }

  /// Revokes Drive access and forgets the account on this device.
  Future<void> disconnect() async {
    try {
      await _ensureInitialized();
      await _signIn.disconnect();
    } catch (_) {
      // Local state is cleared regardless; a failed revoke is not fatal.
    }
  }
}
