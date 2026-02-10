/// URLs for legal pages and support. Used for App Store / Google Play compliance.
/// Use --dart-define to override, or defaults below.
class LegalUrls {
  LegalUrls._();

  static String get privacyPolicy =>
      const String.fromEnvironment(
        'PRIVACY_POLICY_URL',
        defaultValue: 'https://scroodge.github.io/MyKid/privacy.html',
      );

  static String get termsOfService =>
      const String.fromEnvironment(
        'TERMS_OF_SERVICE_URL',
        defaultValue: 'https://scroodge.github.io/MyKid/terms.html',
      );

  static String get support =>
      const String.fromEnvironment(
        'SUPPORT_URL',
        defaultValue: 'mailto:support@mykidapp.com',
      );

  static String get accountDeletion =>
      const String.fromEnvironment(
        'ACCOUNT_DELETION_URL',
        defaultValue: 'mailto:support@mykidapp.com?subject=Account%20Deletion%20Request',
      );

  static String get dataExport =>
      const String.fromEnvironment(
        'DATA_EXPORT_URL',
        defaultValue: 'mailto:support@mykidapp.com?subject=Data%20Export%20Request',
      );

  /// Source code repository URL. Override via SOURCE_CODE_URL env/dart-define.
  static String get sourceCode =>
      const String.fromEnvironment(
        'SOURCE_CODE_URL',
        defaultValue: 'https://github.com/scroodge/MyKid',
      );

  /// GitHub Sponsors or similar donation URL. Override via SPONSOR_URL env/dart-define.
  static String get sponsor =>
      const String.fromEnvironment(
        'SPONSOR_URL',
        defaultValue: 'https://github.com/sponsors/scroodge',
      );
}
