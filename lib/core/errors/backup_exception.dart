import 'dart:async';
import 'dart:io';

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:googleapis/drive/v3.dart' show DetailedApiRequestError;
import 'package:http/http.dart' as http;

enum BackupFailure {
  offline('Tiada sambungan internet. Cuba lagi bila dah online.'),
  notConfigured(
    'Google Sign-In belum disetup untuk app ni. Rujuk README (OAuth client ID).',
  ),
  cancelled('Dibatalkan.'),
  notAuthorized('Akses Google Drive dah tamat. Pilih akaun Google semula.'),
  noAccount('Pilih akaun Google dulu.'),
  corruptFile('Fail backup rosak atau format tak dikenali.'),
  unknown('Ralat tak dijangka. Cuba lagi sekejap lagi.');

  const BackupFailure(this.message);

  /// User-facing Malay message.
  final String message;
}

/// Every backup/restore error is normalised to this, so callers only deal
/// with one type.
class BackupException implements Exception {
  const BackupException(this.failure, [this.detail]);

  /// Classifies network, Drive and Google Sign-In errors.
  factory BackupException.from(Object error) {
    if (error is BackupException) return error;
    return BackupException(_classify(error), error.toString());
  }

  final BackupFailure failure;
  final String? detail;

  /// Worth retrying later without user action.
  bool get isTransient =>
      failure == BackupFailure.offline || failure == BackupFailure.unknown;

  static BackupFailure _classify(Object error) => switch (error) {
    SocketException() ||
    HandshakeException() ||
    TimeoutException() ||
    http.ClientException() => BackupFailure.offline,
    DetailedApiRequestError(status: 401 || 403) => BackupFailure.notAuthorized,
    FormatException() => BackupFailure.corruptFile,
    GoogleSignInException(code: final code) => switch (code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted => BackupFailure.cancelled,
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        BackupFailure.notConfigured,
      GoogleSignInExceptionCode.uiUnavailable => BackupFailure.notAuthorized,
      _ => BackupFailure.unknown,
    },
    _ => BackupFailure.unknown,
  };

  @override
  String toString() => 'BackupException(${failure.name}, $detail)';
}
