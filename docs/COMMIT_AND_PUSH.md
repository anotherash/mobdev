# Как самому сделать коммит и push

Подготовлена отдельная копия репозитория в `/Users/kirkramar/Documents/MobileDevLab2/mobdev`, ветка `lab-2`. Файлы добавлены в индекс (`git add -A`), но новый коммит и push не выполнены. Автора-бота и `Co-authored-by` нет.

## 1. Проверить место, ветку, адрес и автора

```sh
cd /Users/kirkramar/Documents/MobileDevLab2/mobdev
git branch --show-current
git remote -v
git config --get user.name
git config --get user.email
git status --short
git diff --cached --stat
```

Ожидаемая ветка: `lab-2`; origin: `https://github.com/anotherash/mobdev.git`. В этой копии перенесены твои прежние настройки автора: `Kir`, `kirkramar.exists@gmail.com`. Если хочешь другое имя или GitHub noreply-адрес, до коммита выполни `git config user.name "Твоё имя"` и `git config user.email "Твой email"`. Это локальные настройки репозитория.

В изменениях есть удаление старого Android-шаблона из корневой `app/`: это ожидаемо. Теперь Android-оболочка Flutter лежит в `android/app/`, а приложение — в `lib/`. Ветка `lab-1` не менялась. Генерируемые сборки, APK, кэши и `local.properties` в индекс не добавлены.

## 2. Создать коммит

```sh
git diff --cached --check
git commit -m "lab-2: add contacts app"
git log -1 --format=fuller
```

Если после подготовки ты менял исходники, перед коммитом выполни `git add -A`. Проверь в `git log`, что Author и Commit — твоё имя и email.

## 3. Отправить свою ветку

```sh
git push -u origin lab-2
```

В дальнейшем достаточно `git push`. Отправка выполняется из твоей учётной записи с твоими сохранёнными данными GitHub. Пароль аккаунта для HTTPS Git не используется; если потребуется вход, используй ранее настроенную авторизацию/токен. Не вставляй токен в файлы проекта или remote URL.

Если GitHub предложит создать pull request, это отдельный шаг: для отправки ветки он не требуется. `main` и `lab-1` этими командами не изменяются. При отказе push не применяй `--force`: сначала посмотри сообщение Git.
