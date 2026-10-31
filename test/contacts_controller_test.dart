import 'dart:async';

import 'package:device_contacts_app/main.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

ContactEntry entry(
  String id,
  String name, {
  List<String> phones = const [],
  List<String> emails = const [],
}) => ContactEntry(
  id: id,
  displayName: name,
  givenName: name,
  familyName: '',
  phones: phones,
  emails: emails,
  company: '',
  jobTitle: '',
);

class FakeContactsRepository extends ContactsRepository {
  List<ContactEntry> contacts = [
    entry(
      'a',
      'Анна',
      phones: ['123', '456'],
      emails: ['anna@example.invalid'],
    ),
    entry('b', 'Борис'),
    entry('e', 'Ёлкин'),
  ];
  ContactAccess access = ContactAccess.granted;
  ContactAccess requested = ContactAccess.granted;
  int reads = 0, requests = 0, checks = 0, settings = 0;
  bool failRead = false, failCheck = false, failSettings = false;
  Completer<List<ContactEntry>>? pending;
  @override
  Future<ContactAccess> checkPermission() async {
    checks++;
    if (failCheck) throw StateError('check');
    return access;
  }

  @override
  Future<ContactAccess> requestPermission() async {
    requests++;
    return access = requested;
  }

  @override
  Future<void> openSettings() async {
    settings++;
    if (failSettings) throw StateError('settings');
  }

  @override
  Future<List<ContactEntry>> loadContacts() async {
    reads++;
    if (failRead) throw StateError('read');
    if (pending != null) return pending!.future;
    return contacts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeContactsRepository repo;
  late ContactsController controller;
  setUp(() {
    repo = FakeContactsRepository();
    controller = ContactsController(repo);
  });
  tearDown(() => controller.dispose());

  test('initialization reads once and sorts names', () async {
    await controller.initialize();
    await controller.initialize();
    expect(repo.reads, 1);
    expect(controller.state, ContactsViewState.ready);
    expect(controller.visibleContacts.map((c) => c.id), ['a', 'b', 'e']);
  });
  test('search and both sorts use cache and normalize Russian names', () async {
    await controller.initialize();
    controller.updateQuery(' ЕЛК ');
    expect(controller.visibleContacts.single.id, 'e');
    controller.updateQuery('');
    controller.toggleSortOrder();
    expect(controller.visibleContacts.map((c) => c.id), ['e', 'b', 'a']);
    controller.toggleSortOrder();
    expect(controller.visibleContacts.first.id, 'a');
    expect(repo.reads, 1);
  });
  test('no matches differs from empty address book', () async {
    await controller.initialize();
    controller.updateQuery('xyz');
    expect(controller.visibleContacts, isEmpty);
    expect(controller.addressBookEmpty, false);
    expect(controller.state, ContactsViewState.ready);
  });
  test('empty book is distinct from denied permission', () async {
    repo.contacts = [];
    await controller.initialize();
    expect(controller.state, ContactsViewState.empty);
  });
  test('initial denial can be requested again', () async {
    repo.access = repo.requested = ContactAccess.denied;
    await controller.initialize();
    expect(controller.state, ContactsViewState.noPermission);
    expect(repo.reads, 0);
    expect(controller.canRequestPermission, true);
    repo.requested = ContactAccess.granted;
    await controller.requestAccess();
    expect(controller.state, ContactsViewState.ready);
    expect(repo.requests, 2);
  });
  test(
    'blocked permission directs to settings without another prompt',
    () async {
      repo.access = ContactAccess.blocked;
      await controller.initialize();
      expect(controller.canRequestPermission, false);
      expect(repo.requests, 0);
      await controller.openAppSettingsPage();
      expect(repo.settings, 1);
      repo.access = ContactAccess.granted;
      await controller.checkOnResume();
      expect(controller.state, ContactsViewState.ready);
      expect(repo.reads, 1);
    },
  );
  test(
    'resume rechecks permission without rereading cached contacts',
    () async {
      await controller.initialize();
      final before = repo.checks;
      await controller.checkOnResume();
      await controller.checkOnResume();
      expect(repo.checks, before + 2);
      expect(repo.reads, 1);
    },
  );
  test('revocation clears cache, subsequent grant reloads while preserving filters', () async {
    await controller.initialize();
    controller.updateQuery('Ан');
    controller.toggleSortOrder();
    repo.access = ContactAccess.blocked;
    await controller.checkOnResume();
    expect(controller.visibleContacts, isEmpty);
    expect(controller.contactById('a'), isNull);
    expect(controller.state, ContactsViewState.noPermission);
    repo.access = ContactAccess.granted;
    await controller.checkOnResume();
    expect(repo.reads, 2);
    expect(controller.query, 'Ан');
    expect(controller.sortOrder, SortOrder.descending);
  });
  test('explicit refresh rereads the book', () async {
    await controller.initialize();
    repo.contacts = [entry('x', 'Новый')];
    await controller.refresh();
    expect(repo.reads, 2);
    expect(controller.visibleContacts.single.id, 'x');
  });
  test('read error can be retried', () async {
    repo.failRead = true;
    await controller.initialize();
    expect(controller.state, ContactsViewState.error);
    repo.failRead = false;
    await controller.refresh();
    expect(controller.state, ContactsViewState.ready);
  });
  test('permission check error is handled', () async {
    repo.failCheck = true;
    await controller.initialize();
    expect(controller.state, ContactsViewState.error);
    expect(repo.reads, 0);
  });
  test('settings failure is available for localized UI', () async {
    repo.failSettings = true;
    await controller.openAppSettingsPage();
    expect(controller.settingsError, true);
  });
  test('concurrent resume and refresh do not duplicate reading', () async {
    repo.pending = Completer();
    final first = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.checkOnResume();
    expect(repo.reads, 1);
    repo.pending!.complete(repo.contacts);
    await first;
    expect(controller.state, ContactsViewState.ready);
  });
  test('revocation during read discards late contacts', () async {
    repo.pending = Completer();
    final first = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    repo.access = ContactAccess.blocked;
    repo.pending!.complete(repo.contacts);
    await first;
    expect(controller.visibleContacts, isEmpty);
    expect(controller.state, ContactsViewState.noPermission);
  });
  test('dispose during reading does not notify a dead widget', () async {
    final separate = ContactsController(repo);
    repo.pending = Completer();
    final first = separate.initialize();
    await Future<void>.delayed(Duration.zero);
    separate.dispose();
    repo.pending!.complete(repo.contacts);
    await first;
  });
  test('mapping selects primary phone and accepts absent optional fields', () {
    final mapped = ContactEntry.fromContact(
      Contact(
        id: '1',
        displayName: 'Анна',
        phones: [
          Phone(number: '111'),
          Phone(number: '222', isPrimary: true),
        ],
      ),
    );
    expect(mapped.primaryPhone, '222');
    expect(mapped.phones, ['222', '111']);
    expect(mapped.hasEmail, false);
    final empty = ContactEntry.fromContact(Contact(id: '2'));
    expect(empty.displayName, '');
    expect(empty.primaryPhone, '');
    expect(empty.emails, isEmpty);
  });
}
