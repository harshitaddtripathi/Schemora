// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'स्कीमोरा';

  @override
  String get welcomeTitle => 'अपने लिए योग्य सरकारी योजनाएं खोजें';

  @override
  String get healthCheckTitle => 'सिस्टम स्थिति';

  @override
  String get loadingText => 'लोड हो रहा है...';

  @override
  String get retryButton => 'पुनः प्रयास करें';

  @override
  String get errorTitle => 'कुछ गलत हो गया';
}
