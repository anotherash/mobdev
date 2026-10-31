# Lab 2 Contacts — AI Context Handoff

## What this archive is
This archive contains a Flutter project prepared for a university lab assignment called **"Lab 2. Contacts"**.

The project was originally based on an existing Flutter repo where a calculator app was already implemented. That calculator implementation was replaced with a contacts app.

## Goal
Help finish, validate, and if needed fix the Flutter implementation so it is ready to run on another laptop and later be committed manually by the user.

## Assignment requirements
Implement a mobile app for viewing and searching device contacts.
Allowed platform: Flutter.

Required functionality:
- Request permission to read contacts.
- Distinguish between **no permission** and **empty address book**.
- Show a contact list with:
  - name
  - primary phone number if present
  - sign/indicator that email exists
- Open contact details on tap with:
  - name
  - all available phones
  - emails
  - extra fields if available
- Search contacts by name **without rereading the whole address book on every keystroke**.
- Sort by name ascending and descending.
- Show number of found records.
- Support states:
  - loading
  - empty list
  - no permission
  - read error
- Add button to request access again; if system dialog is unavailable, offer opening app settings.
- After returning from settings, re-check permission and refresh data if needed.
- Do not reload contacts on ordinary rebuild or when returning from details screen.

Reliability and restrictions:
- App must not crash when permission is denied/revoked, when phone/email is missing, or when address book is empty.
- Use lazy list (`ListView.builder` in Flutter).
- Avoid overlap with unsafe/system areas.
- Work in portrait and landscape.
- Do not use package/bundle id of the form `com.example...`.
- UI strings should be localized via resources, not hardcoded.

Manual demo scenarios expected during defense:
- deny permission
- grant permission
- show list and contact details
- search and both sorts
- empty search result
- return from settings
- rotate screen without losing current search and chosen sort

## What was already changed
Main changed files:
- `project/lib/main.dart`
- `project/lib/l10n/app_ru.arb`
- `project/lib/l10n/app_en.arb`
- `project/pubspec.yaml`
- `project/android/app/src/main/AndroidManifest.xml`
- `project/test/widget_test.dart`
- `project/test/contacts_controller_test.dart`

Old calculator files removed:
- `project/lib/calculator_engine.dart`
- `project/lib/calculator_model.dart`
- `project/test/calculator_test.dart`

## Important environment notes
- The source environment could edit files, but could not fully validate with Flutter because network access was restricted.
- A `flutter test` attempt failed due to inability to resolve `github.com` while Flutter/tooling was trying to fetch/update something.
- Because of that, assume the code is a **prepared draft**, not fully verified on-device.
- There is **no iOS folder** in this project snapshot, so only Android-related setup was updated.

## Your task as the receiving AI
Please do the following carefully:
1. Read the project.
2. Run or instruct to run:
   - `flutter pub get`
   - `flutter gen-l10n`
   - `flutter analyze`
   - `flutter test`
   - `flutter run`
3. Fix compile/runtime/plugin issues if they appear.
4. Check whether the implementation really satisfies the assignment.
5. Pay special attention to:
   - permission flow
   - no unnecessary reloads
   - search using cached data
   - state preservation on rotation
   - localization usage
   - package id constraint
6. If code quality can be improved with small safe changes, do it.
7. Prepare a concise summary of:
   - what was fixed
   - what still needs manual testing
   - exact git commands the user should run manually

## Hints / likely problem areas
- `contacts_service` and `permission_handler` versions may require local compatibility adjustments.
- Localization generation may need to be run before analysis/tests.
- Some widget tests may need updates after generation or dependency resolution.
- State preservation for rotation may need verification beyond current implementation.

## Constraints
- Do not assume the app is production-grade; it only needs to satisfy the lab requirements cleanly.
- Keep changes minimal and focused.
- The user wants to commit manually later.
