import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

void main() {
  runApp(const ContactsApp());
}

enum SortOrder { ascending, descending }

enum ContactsViewState { loading, ready, empty, noPermission, error }

class ContactEntry {
  const ContactEntry({
    required this.id,
    required this.displayName,
    required this.givenName,
    required this.familyName,
    required this.phones,
    required this.emails,
    required this.company,
    required this.jobTitle,
    this.addresses = const [],
    this.notes = const [],
    this.websites = const [],
    this.dates = const [],
  });

  factory ContactEntry.fromContact(Contact contact) {
    List<String> clean(Iterable<String?> values) => values
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    final phones = [...contact.phones]
      ..sort(
        (a, b) => (b.isPrimary == true ? 1 : 0).compareTo(
          a.isPrimary == true ? 1 : 0,
        ),
      );
    final givenName = contact.name?.first?.trim() ?? '';
    final familyName = contact.name?.last?.trim() ?? '';
    final composedName = clean([givenName, familyName]).join(' ');
    final displayName = (contact.displayName?.trim().isNotEmpty ?? false)
        ? contact.displayName!.trim()
        : composedName;
    return ContactEntry(
      id: contact.id ?? displayName,
      displayName: displayName,
      givenName: givenName,
      familyName: familyName,
      phones: clean(phones.map((p) => p.number)),
      emails: clean(contact.emails.map((e) => e.address)),
      company: contact.organizations.firstOrNull?.name?.trim() ?? '',
      jobTitle: contact.organizations.firstOrNull?.jobTitle?.trim() ?? '',
      addresses: clean(
        contact.addresses.map(
          (a) => (a.formatted?.trim().isNotEmpty ?? false)
              ? a.formatted
              : clean([a.street, a.city, a.state, a.postalCode, a.country])
                    .join(', '),
        ),
      ),
      notes: clean(contact.notes.map((n) => n.note)),
      websites: clean(contact.websites.map((w) => w.url)),
      dates: contact.events
          .map(
            (e) => [
              e.day.toString().padLeft(2, '0'),
              e.month.toString().padLeft(2, '0'),
              if (e.year != null) e.year.toString(),
            ].join('.'),
          )
          .toList(),
    );
  }

  final String id;
  final String displayName;
  final String givenName;
  final String familyName;
  final List<String> phones;
  final List<String> emails;
  final String company;
  final String jobTitle;
  final List<String> addresses, notes, websites, dates;

  String get primaryPhone => phones.isEmpty ? '' : phones.first;
  bool get hasEmail => emails.isNotEmpty;
}

enum ContactAccess { granted, denied, blocked }

class ContactsRepository {
  bool _blocked = false;
  ContactAccess _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited => ContactAccess.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => ContactAccess.blocked,
    _ => ContactAccess.denied,
  };
  Future<ContactAccess> checkPermission() async {
    final status = await FlutterContacts.permissions.check(PermissionType.read);
    // На Android плагин может вернуть notDetermined после окончательного отказа.
    if (status == PermissionStatus.notDetermined && _blocked) {
      return ContactAccess.blocked;
    }
    final access = _map(status);
    if (access == ContactAccess.granted || status == PermissionStatus.denied) {
      _blocked = false;
    }
    return access;
  }

  Future<ContactAccess> requestPermission() async {
    final access = _map(
      await FlutterContacts.permissions.request(PermissionType.read),
    );
    _blocked = access == ContactAccess.blocked;
    return access;
  }

  Future<void> openSettings() => FlutterContacts.permissions.openSettings();
  Future<List<ContactEntry>> loadContacts() async {
    final contacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.phone,
        ContactProperty.email,
        ContactProperty.organization,
        ContactProperty.address,
        ContactProperty.note,
        ContactProperty.website,
        ContactProperty.event,
      },
    );
    return contacts.map(ContactEntry.fromContact).toList(growable: false);
  }
}

class ContactsController extends ChangeNotifier with WidgetsBindingObserver {
  ContactsController(this._repository);
  final ContactsRepository _repository;
  ContactsViewState _state = ContactsViewState.loading;
  SortOrder _sortOrder = SortOrder.ascending;
  List<ContactEntry> _allContacts = const [];
  List<ContactEntry> _visibleContacts = const [];
  String _query = '';
  bool _canRequestPermission = true;
  bool _started = false, _busy = false, _disposed = false, _loaded = false;
  bool _settingsError = false;
  ContactsViewState get state => _state;
  SortOrder get sortOrder => _sortOrder;
  List<ContactEntry> get visibleContacts => _visibleContacts;
  String get query => _query;
  bool get canRequestPermission => _canRequestPermission;
  bool get settingsError => _settingsError;
  ContactEntry? contactById(String id) =>
      _allContacts.where((c) => c.id == id).firstOrNull;
  bool get addressBookEmpty => _allContacts.isEmpty;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _synchronize(request: true);
  }

  Future<void> refresh() => _synchronize(force: true);
  Future<void> requestAccess() => _synchronize(request: true, force: true);
  Future<void> checkOnResume() => _synchronize();
  void _clearContacts() {
    _allContacts = const [];
    _visibleContacts = const [];
    _loaded = false;
  }

  Future<void> _synchronize({bool request = false, bool force = false}) async {
    if (_busy || _disposed) return;
    _busy = true;
    _settingsError = false;
    try {
      var permission = await _repository.checkPermission();
      if (_disposed) return;
      if (request && permission == ContactAccess.denied) {
        permission = await _repository.requestPermission();
      }
      if (_disposed) return;
      _canRequestPermission = permission != ContactAccess.blocked;
      if (permission != ContactAccess.granted) {
        _clearContacts();
        _state = ContactsViewState.noPermission;
        return;
      }
      // resumed проверяет доступ, но не перечитывает уже загруженную книгу.
      if (_loaded && !force) return;
      _state = ContactsViewState.loading;
      _notify();
      final contacts = await _repository.loadContacts();
      permission = await _repository.checkPermission();
      if (_disposed) return;
      if (permission != ContactAccess.granted) {
        _canRequestPermission = permission != ContactAccess.blocked;
        _clearContacts();
        _state = ContactsViewState.noPermission;
        return;
      }
      _allContacts = contacts;
      _loaded = true;
      _applyFilters();
      _state = _allContacts.isEmpty
          ? ContactsViewState.empty
          : ContactsViewState.ready;
    } catch (_) {
      if (!_disposed) {
        _clearContacts();
        _state = ContactsViewState.error;
        try {
          final permission = await _repository.checkPermission();
          _canRequestPermission = permission != ContactAccess.blocked;
          if (permission != ContactAccess.granted) {
            _state = ContactsViewState.noPermission;
          }
        } catch (_) {
          /* Ошибка проверки разрешения остаётся состоянием error. */
        }
      }
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> openAppSettingsPage() async {
    try {
      await _repository.openSettings();
    } catch (_) {
      _settingsError = true;
      _notify();
    }
  }

  void updateQuery(String value) {
    _query = value;
    _applyFilters();
    _notify();
  }

  void toggleSortOrder() {
    setSortOrder(
      _sortOrder == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending,
    );
  }

  void setSortOrder(SortOrder value) {
    _sortOrder = value;
    _applyFilters();
    _notify();
  }

  void _applyFilters() {
    String normalize(String v) => v.trim().toLowerCase().replaceAll('ё', 'е');
    final normalizedQuery = normalize(_query);
    final filtered = _allContacts
        .where(
          (contact) =>
              normalize(contact.displayName).contains(normalizedQuery) ||
              normalize(contact.givenName).contains(normalizedQuery) ||
              normalize(contact.familyName).contains(normalizedQuery),
        )
        .toList();
    filtered.sort((left, right) {
      if (left.displayName.isEmpty != right.displayName.isEmpty) {
        return left.displayName.isEmpty ? 1 : -1;
      }
      var result = normalize(left.displayName)
          .compareTo(normalize(right.displayName));
      if (result == 0) result = left.id.compareTo(right.id);
      return _sortOrder == SortOrder.ascending ? result : -result;
    });
    _visibleContacts = filtered;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(checkOnResume());
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ContactsApp extends StatefulWidget {
  final ContactsController? controller;
  const ContactsApp({super.key, this.controller});
  @override
  State<ContactsApp> createState() => _ContactsAppState();
}

class _ContactsAppState extends State<ContactsApp> {
  late final ContactsController controller =
      widget.controller ?? ContactsController(ContactsRepository());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      restorationScopeId: 'contacts_app',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: ContactsScreen(controller: controller),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.controller});

  final ContactsController controller;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with RestorationMixin {
  final _savedQuery = RestorableString('');
  final _savedDescending = RestorableBool(false);
  @override
  String get restorationId => 'contacts_screen';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_savedQuery, 'query');
    registerForRestoration(_savedDescending, 'descending');
    _searchController.text = _savedQuery.value;
    controller.updateQuery(_savedQuery.value);
    controller.setSortOrder(
      _savedDescending.value ? SortOrder.descending : SortOrder.ascending,
    );
  }

  void _toggleSort() {
    controller.toggleSortOrder();
    _savedDescending.value = controller.sortOrder == SortOrder.descending;
  }

  late final TextEditingController _searchController;

  ContactsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(controller.initialize());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _savedQuery.dispose();
    _savedDescending.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.appTitle),
            actions: [
              IconButton(
                onPressed: controller.openAppSettingsPage,
                tooltip: strings.openSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                onPressed: controller.state == ContactsViewState.loading
                    ? null
                    : controller.refresh,
                tooltip: strings.refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: _toggleSort,
                icon: Icon(
                  controller.sortOrder == SortOrder.ascending
                      ? Icons.sort_by_alpha
                      : Icons.sort,
                ),
                tooltip: controller.sortOrder == SortOrder.ascending
                    ? strings.sortAscending
                    : strings.sortDescending,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: SizedBox(
                  height: math.max(constraints.maxHeight, 260),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          key: const ValueKey('search'),
                          onChanged: (value) {
                            _savedQuery.value = value;
                            controller.updateQuery(value);
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              tooltip: strings.clearSearch,
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _savedQuery.value = '';
                                controller.updateQuery('');
                              },
                            ),
                            hintText: strings.searchHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ChoiceChip(
                              label: Text(strings.sortAscending),
                              selected:
                                  controller.sortOrder == SortOrder.ascending,
                              onSelected: (_) {
                                if (controller.sortOrder !=
                                    SortOrder.ascending) {
                                  _toggleSort();
                                }
                              },
                            ),
                            ChoiceChip(
                              label: Text(strings.sortDescending),
                              selected:
                                  controller.sortOrder == SortOrder.descending,
                              onSelected: (_) {
                                if (controller.sortOrder !=
                                    SortOrder.descending) {
                                  _toggleSort();
                                }
                              },
                            ),
                            Text(
                              strings.foundCount(
                                controller.visibleContacts.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildBody(context, strings)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations strings) {
    switch (controller.state) {
      case ContactsViewState.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(strings.loading),
            ],
          ),
        );
      case ContactsViewState.noPermission:
        return StatusState(
          icon: Icons.lock_outline,
          title: strings.noPermissionTitle,
          description: controller.settingsError
              ? strings.settingsError
              : controller.canRequestPermission
              ? strings.noPermissionDescription
              : strings.permissionBlockedDescription,
          actions: [
            FilledButton(
              onPressed: controller.canRequestPermission
                  ? controller.requestAccess
                  : controller.openAppSettingsPage,
              child: Text(
                controller.canRequestPermission
                    ? strings.requestAccess
                    : strings.openSettings,
              ),
            ),
          ],
        );
      case ContactsViewState.error:
        return StatusState(
          icon: Icons.error_outline,
          title: strings.readErrorTitle,
          description: strings.readErrorDescription,
          actions: [
            FilledButton(
              onPressed: controller.refresh,
              child: Text(strings.retry),
            ),
          ],
        );
      case ContactsViewState.empty:
        return controller.addressBookEmpty
            ? StatusState(
                icon: Icons.contact_page_outlined,
                title: strings.emptyContactsTitle,
                description: strings.emptyContactsDescription,
              )
            : StatusState(
                icon: Icons.search_off,
                title: strings.emptySearchTitle,
                description: strings.emptySearchDescription,
              );
      case ContactsViewState.ready:
        if (controller.visibleContacts.isEmpty) {
          return StatusState(
            icon: Icons.search_off,
            title: strings.emptySearchTitle,
            description: strings.emptySearchDescription,
          );
        }
        return ListView.builder(
          itemCount: controller.visibleContacts.length,
          itemBuilder: (context, index) {
            final contact = controller.visibleContacts[index];
            final firstCharacter = contact.displayName.isEmpty
                ? '?'
                : contact.displayName.characters.first;
            return ListTile(
              leading: CircleAvatar(child: Text(firstCharacter)),
              key: ValueKey('contact_${contact.id}'),
              title: Text(
                contact.displayName.isEmpty
                    ? strings.unnamed
                    : contact.displayName,
              ),
              subtitle: Text(
                contact.primaryPhone.isEmpty
                    ? strings.noPhone
                    : contact.primaryPhone,
              ),
              trailing: contact.hasEmail
                  ? Tooltip(
                      message: strings.hasEmail,
                      child: const Icon(Icons.email_outlined),
                    )
                  : null,
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ContactDetailsScreen(
                      contact: contact,
                      controller: controller,
                    ),
                  ),
                );
              },
            );
          },
        );
    }
  }
}

class ContactDetailsScreen extends StatelessWidget {
  const ContactDetailsScreen({
    super.key,
    required this.contact,
    required this.controller,
  });

  final ContactsController controller;

  final ContactEntry contact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.contactById(contact.id);
        final entry = current;
        return Scaffold(
          appBar: AppBar(title: Text(strings.detailsTitle)),
          body: SafeArea(
            child: controller.state == ContactsViewState.noPermission
                ? StatusState(
                    icon: Icons.lock_outline,
                    title: strings.noPermissionTitle,
                    description: controller.canRequestPermission
                        ? strings.noPermissionDescription
                        : strings.permissionBlockedDescription,
                    actions: [
                      FilledButton(
                        onPressed: controller.canRequestPermission
                            ? controller.requestAccess
                            : controller.openAppSettingsPage,
                        child: Text(
                          controller.canRequestPermission
                              ? strings.requestAccess
                              : strings.openSettings,
                        ),
                      ),
                    ],
                  )
                : controller.state == ContactsViewState.error
                ? StatusState(
                    icon: Icons.error_outline,
                    title: strings.readErrorTitle,
                    description: strings.readErrorDescription,
                    actions: [
                      FilledButton(
                        onPressed: controller.refresh,
                        child: Text(strings.retry),
                      ),
                    ],
                  )
                : controller.state == ContactsViewState.loading
                ? const Center(child: CircularProgressIndicator())
                : entry == null
                ? StatusState(
                    icon: Icons.person_off_outlined,
                    title: strings.contactMissing,
                    description: strings.returnToList,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        entry.displayName.isEmpty
                            ? strings.unnamed
                            : entry.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      DetailsSection(
                        title: strings.phonesSection,
                        values: entry.phones,
                        emptyLabel: strings.notSpecified,
                      ),
                      const SizedBox(height: 16),
                      DetailsSection(
                        title: strings.emailsSection,
                        values: entry.emails,
                        emptyLabel: strings.notSpecified,
                      ),
                      const SizedBox(height: 16),
                      FactsSection(contact: entry),
                      for (final section in <String, List<String>>{
                        strings.addressesSection: entry.addresses,
                        strings.notesSection: entry.notes,
                        strings.websitesSection: entry.websites,
                        strings.datesSection: entry.dates,
                      }.entries)
                        if (section.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: DetailsSection(
                              title: section.key,
                              values: section.value,
                              emptyLabel: strings.notSpecified,
                            ),
                          ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class FactsSection extends StatelessWidget {
  const FactsSection({super.key, required this.contact});

  final ContactEntry contact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final rows = <MapEntry<String, String>>[
      MapEntry(strings.displayName, contact.displayName),
      MapEntry(strings.givenName, contact.givenName),
      MapEntry(strings.familyName, contact.familyName),
      MapEntry(strings.organization, contact.company),
      MapEntry(strings.jobTitle, contact.jobTitle),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.otherSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.value.isEmpty ? strings.notSpecified : row.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsSection extends StatelessWidget {
  const DetailsSection({
    super.key,
    required this.title,
    required this.values,
    required this.emptyLabel,
  });

  final String title;
  final List<String> values;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (values.isEmpty) Text(emptyLabel),
            ...values.map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusState extends StatelessWidget {
  const StatusState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
