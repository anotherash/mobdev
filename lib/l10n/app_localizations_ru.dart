// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Контакты';

  @override
  String get searchHint => 'Поиск по имени';

  @override
  String get sortAscending => 'А-Я';

  @override
  String get sortDescending => 'Я-А';

  @override
  String foundCount(int count) {
    return 'Найдено: $count';
  }

  @override
  String get loading => 'Загрузка контактов…';

  @override
  String get noPermissionTitle => 'Нет доступа к контактам';

  @override
  String get noPermissionDescription =>
      'Разрешите доступ к контактам, чтобы показать адресную книгу.';

  @override
  String get requestAccess => 'Запросить доступ';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get emptyContactsTitle => 'Адресная книга пуста';

  @override
  String get emptyContactsDescription =>
      'На этом устройстве не найдено контактов.';

  @override
  String get emptySearchTitle => 'Ничего не найдено';

  @override
  String get emptySearchDescription => 'Попробуйте другой поисковый запрос.';

  @override
  String get readErrorTitle => 'Не удалось прочитать контакты';

  @override
  String get retry => 'Повторить';

  @override
  String get hasEmail => 'Есть email';

  @override
  String get noPhone => 'Нет номера телефона';

  @override
  String get detailsTitle => 'Детали контакта';

  @override
  String get phonesSection => 'Номера телефонов';

  @override
  String get emailsSection => 'Адреса email';

  @override
  String get otherSection => 'Дополнительная информация';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get organization => 'Организация';

  @override
  String get jobTitle => 'Должность';

  @override
  String get givenName => 'Имя';

  @override
  String get familyName => 'Фамилия';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get refresh => 'Обновить';

  @override
  String get unnamed => 'Без имени';

  @override
  String get permissionBlockedDescription =>
      'Повторный системный запрос недоступен. Разрешите доступ в настройках приложения.';

  @override
  String get settingsError =>
      'Не удалось открыть настройки. Откройте настройки приложения через меню Android.';

  @override
  String get readErrorDescription =>
      'Проверьте доступ к контактам и попробуйте ещё раз.';

  @override
  String get addressesSection => 'Адреса';

  @override
  String get notesSection => 'Заметки';

  @override
  String get websitesSection => 'Сайты';

  @override
  String get datesSection => 'Даты';

  @override
  String get contactMissing => 'Контакт больше не доступен';

  @override
  String get returnToList => 'Вернитесь к списку контактов.';
}
