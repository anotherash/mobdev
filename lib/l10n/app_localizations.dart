import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get appTitle;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени'**
  String get searchHint;

  /// No description provided for @sortAscending.
  ///
  /// In ru, this message translates to:
  /// **'А-Я'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In ru, this message translates to:
  /// **'Я-А'**
  String get sortDescending;

  /// No description provided for @foundCount.
  ///
  /// In ru, this message translates to:
  /// **'Найдено: {count}'**
  String foundCount(int count);

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка контактов…'**
  String get loading;

  /// No description provided for @noPermissionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к контактам'**
  String get noPermissionTitle;

  /// No description provided for @noPermissionDescription.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к контактам, чтобы показать адресную книгу.'**
  String get noPermissionDescription;

  /// No description provided for @requestAccess.
  ///
  /// In ru, this message translates to:
  /// **'Запросить доступ'**
  String get requestAccess;

  /// No description provided for @openSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get openSettings;

  /// No description provided for @emptyContactsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Адресная книга пуста'**
  String get emptyContactsTitle;

  /// No description provided for @emptyContactsDescription.
  ///
  /// In ru, this message translates to:
  /// **'На этом устройстве не найдено контактов.'**
  String get emptyContactsDescription;

  /// No description provided for @emptySearchTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchDescription.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другой поисковый запрос.'**
  String get emptySearchDescription;

  /// No description provided for @readErrorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать контакты'**
  String get readErrorTitle;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @hasEmail.
  ///
  /// In ru, this message translates to:
  /// **'Есть email'**
  String get hasEmail;

  /// No description provided for @noPhone.
  ///
  /// In ru, this message translates to:
  /// **'Нет номера телефона'**
  String get noPhone;

  /// No description provided for @detailsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Детали контакта'**
  String get detailsTitle;

  /// No description provided for @phonesSection.
  ///
  /// In ru, this message translates to:
  /// **'Номера телефонов'**
  String get phonesSection;

  /// No description provided for @emailsSection.
  ///
  /// In ru, this message translates to:
  /// **'Адреса email'**
  String get emailsSection;

  /// No description provided for @otherSection.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительная информация'**
  String get otherSection;

  /// No description provided for @notSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get notSpecified;

  /// No description provided for @organization.
  ///
  /// In ru, this message translates to:
  /// **'Организация'**
  String get organization;

  /// No description provided for @jobTitle.
  ///
  /// In ru, this message translates to:
  /// **'Должность'**
  String get jobTitle;

  /// No description provided for @givenName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get givenName;

  /// No description provided for @familyName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get familyName;

  /// No description provided for @displayName.
  ///
  /// In ru, this message translates to:
  /// **'Отображаемое имя'**
  String get displayName;

  /// No description provided for @clearSearch.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get clearSearch;

  /// No description provided for @refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get refresh;

  /// No description provided for @unnamed.
  ///
  /// In ru, this message translates to:
  /// **'Без имени'**
  String get unnamed;

  /// No description provided for @permissionBlockedDescription.
  ///
  /// In ru, this message translates to:
  /// **'Повторный системный запрос недоступен. Разрешите доступ в настройках приложения.'**
  String get permissionBlockedDescription;

  /// No description provided for @settingsError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть настройки. Откройте настройки приложения через меню Android.'**
  String get settingsError;

  /// No description provided for @readErrorDescription.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте доступ к контактам и попробуйте ещё раз.'**
  String get readErrorDescription;

  /// No description provided for @addressesSection.
  ///
  /// In ru, this message translates to:
  /// **'Адреса'**
  String get addressesSection;

  /// No description provided for @notesSection.
  ///
  /// In ru, this message translates to:
  /// **'Заметки'**
  String get notesSection;

  /// No description provided for @websitesSection.
  ///
  /// In ru, this message translates to:
  /// **'Сайты'**
  String get websitesSection;

  /// No description provided for @datesSection.
  ///
  /// In ru, this message translates to:
  /// **'Даты'**
  String get datesSection;

  /// No description provided for @contactMissing.
  ///
  /// In ru, this message translates to:
  /// **'Контакт больше не доступен'**
  String get contactMissing;

  /// No description provided for @returnToList.
  ///
  /// In ru, this message translates to:
  /// **'Вернитесь к списку контактов.'**
  String get returnToList;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
