/// Google OAuth client IDs, injected at build time so no secrets live in git:
///
/// ```
/// flutter run --dart-define-from-file=google_oauth.json
/// ```
///
/// See README → "Google Drive backup setup".
abstract final class GoogleConfig {
  /// Web client ID. Android's account picker (Credential Manager) needs it.
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// iOS client ID (iOS also needs its reversed ID as a URL scheme).
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static String? get serverClientIdOrNull =>
      serverClientId.isEmpty ? null : serverClientId;

  static String? get iosClientIdOrNull =>
      iosClientId.isEmpty ? null : iosClientId;
}
