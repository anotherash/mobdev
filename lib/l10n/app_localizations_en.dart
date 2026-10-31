// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Contacts';

  @override
  String get searchHint => 'Search by name';

  @override
  String get sortAscending => 'A-Z';

  @override
  String get sortDescending => 'Z-A';

  @override
  String foundCount(int count) {
    return 'Found: $count';
  }

  @override
  String get loading => 'Loading contacts…';

  @override
  String get noPermissionTitle => 'No access to contacts';

  @override
  String get noPermissionDescription =>
      'Allow access to contacts to display the address book.';

  @override
  String get requestAccess => 'Request access';

  @override
  String get openSettings => 'Open settings';

  @override
  String get emptyContactsTitle => 'Address book is empty';

  @override
  String get emptyContactsDescription =>
      'No contacts were found on this device.';

  @override
  String get emptySearchTitle => 'Nothing found';

  @override
  String get emptySearchDescription => 'Try another search query.';

  @override
  String get readErrorTitle => 'Failed to read contacts';

  @override
  String get retry => 'Retry';

  @override
  String get hasEmail => 'Email available';

  @override
  String get noPhone => 'No phone number';

  @override
  String get detailsTitle => 'Contact details';

  @override
  String get phonesSection => 'Phone numbers';

  @override
  String get emailsSection => 'Email addresses';

  @override
  String get otherSection => 'Additional information';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get organization => 'Organization';

  @override
  String get jobTitle => 'Job title';

  @override
  String get givenName => 'First name';

  @override
  String get familyName => 'Last name';

  @override
  String get displayName => 'Display name';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get refresh => 'Refresh';

  @override
  String get unnamed => 'Unnamed';

  @override
  String get permissionBlockedDescription =>
      'The system prompt is unavailable. Allow contact access in app settings.';

  @override
  String get settingsError =>
      'Could not open settings. Open app settings from the Android system menu.';

  @override
  String get readErrorDescription => 'Check contact access and try again.';

  @override
  String get addressesSection => 'Addresses';

  @override
  String get notesSection => 'Notes';

  @override
  String get websitesSection => 'Websites';

  @override
  String get datesSection => 'Dates';

  @override
  String get contactMissing => 'Contact is no longer available';

  @override
  String get returnToList => 'Return to the contact list.';
}
