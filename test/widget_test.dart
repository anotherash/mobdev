import 'package:device_contacts_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contacts_controller_test.dart' as fixtures;

void main() {
  late fixtures.FakeContactsRepository repo;
  late ContactsController controller;
  setUp(() {
    repo = fixtures.FakeContactsRepository();
    controller = ContactsController(repo);
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(ContactsApp(controller: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('list, details, missing fields and back use one cached read', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Найдено: 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('contact_a')));
    await tester.pumpAndSettle();
    expect(find.text('123'), findsOneWidget);
    expect(find.text('456'), findsOneWidget);
    expect(find.text('anna@example.invalid'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('contact_b')));
    await tester.pumpAndSettle();
    expect(find.text('Не указано'), findsWidgets);
    expect(repo.reads, 1);
  });
  testWidgets('search, empty result, clear and descending sort', (
    tester,
  ) async {
    await launch(tester);
    await tester.enterText(find.byType(TextField), 'Ан');
    await tester.pumpAndSettle();
    expect(find.text('Найдено: 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    await tester.tap(find.byTooltip('Очистить поиск'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Я-А'));
    await tester.pumpAndSettle();
    expect(controller.visibleContacts.first.id, 'e');
    expect(repo.reads, 1);
  });
  testWidgets(
    'permission denial is distinct from an empty book and can retry',
    (tester) async {
      repo.access = repo.requested = ContactAccess.denied;
      await launch(tester);
      expect(find.text('Нет доступа к контактам'), findsOneWidget);
      expect(find.text('Адресная книга пуста'), findsNothing);
      repo.requested = ContactAccess.granted;
      repo.contacts = [];
      await tester.tap(find.text('Запросить доступ'));
      await tester.pumpAndSettle();
      expect(find.text('Адресная книга пуста'), findsOneWidget);
    },
  );
  testWidgets('blocked permission opens settings', (tester) async {
    repo.access = ContactAccess.blocked;
    await launch(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Открыть настройки'));
    await tester.pumpAndSettle();
    expect(repo.settings, 1);
    expect(repo.requests, 0);
  });
  testWidgets('read error has a working retry', (tester) async {
    repo.failRead = true;
    await launch(tester);
    expect(find.text('Не удалось прочитать контакты'), findsOneWidget);
    repo.failRead = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Найдено: 3'), findsOneWidget);
  });
  testWidgets(
    'portrait, landscape and small keyboard viewport preserve filters',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await launch(tester);
      await tester.enterText(find.byType(TextField), 'Ан');
      await tester.tap(find.text('Я-А'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.query, 'Ан');
      expect(controller.sortOrder, SortOrder.descending);
      tester.view.physicalSize = const Size(640, 170);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.reads, 1);
    },
  );
  testWidgets('details hide revoked data and handle deleted contact on grant', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey('contact_a')));
    await tester.pumpAndSettle();
    repo.access = ContactAccess.blocked;
    await controller.checkOnResume();
    await tester.pumpAndSettle();
    expect(find.text('anna@example.invalid'), findsNothing);
    expect(find.text('Нет доступа к контактам'), findsOneWidget);
    repo.contacts = [];
    repo.access = ContactAccess.granted;
    await controller.checkOnResume();
    await tester.pumpAndSettle();
    expect(find.text('Контакт больше не доступен'), findsOneWidget);
  });
}
