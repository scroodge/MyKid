import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URLs for legal pages and support. Used for App Store / Google Play compliance.
/// Load from .env or use defaults. Set empty string to hide a section.
class LegalUrls {
  LegalUrls._();

  static String get privacyPolicy =>
      dotenv.env['PRIVACY_POLICY_URL'] ??
      const String.fromEnvironment(
        'PRIVACY_POLICY_URL',
        defaultValue: 'https://mykidapp.com/privacy',
      );

  static String get termsOfService =>
      dotenv.env['TERMS_OF_SERVICE_URL'] ??
      const String.fromEnvironment(
        'TERMS_OF_SERVICE_URL',
        defaultValue: 'https://mykidapp.com/terms',
      );

  static String get support =>
      dotenv.env['SUPPORT_URL'] ??
      const String.fromEnvironment(
        'SUPPORT_URL',
        defaultValue: 'mailto:support@mykidapp.com',
      );

  static String get accountDeletion =>
      dotenv.env['ACCOUNT_DELETION_URL'] ??
      const String.fromEnvironment(
        'ACCOUNT_DELETION_URL',
        defaultValue: 'mailto:support@mykidapp.com?subject=Account%20Deletion%20Request',
      );

  static String get dataExport =>
      dotenv.env['DATA_EXPORT_URL'] ??
      const String.fromEnvironment(
        'DATA_EXPORT_URL',
        defaultValue: 'mailto:support@mykidapp.com?subject=Data%20Export%20Request',
      );
}
