// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Schemora';

  @override
  String get welcomeTitle => 'Find Government Schemes You Qualify For';

  @override
  String get healthCheckTitle => 'System Status';

  @override
  String get loadingText => 'Loading...';

  @override
  String get retryButton => 'Retry';

  @override
  String get errorTitle => 'Something went wrong';
}
