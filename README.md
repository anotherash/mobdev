# Контакты

Приложение на Flutter для Android.

## Запуск

Требуются Flutter SDK, Android SDK и запущенный Android-эмулятор либо подключённое устройство с включённой USB-отладкой.

Откройте корневую папку проекта и выполните:

```sh
flutter pub get
flutter gen-l10n
flutter run
```

Если подключено несколько устройств:

```sh
flutter devices
flutter run -d <device-id>
```

При первом запуске разрешите доступ к контактам.

## Сборка APK

```sh
flutter build apk --debug
```

Файл сборки: `build/app/outputs/flutter-apk/app-debug.apk`.
