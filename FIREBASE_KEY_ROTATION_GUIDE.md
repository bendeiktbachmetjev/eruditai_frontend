# 🔐 Руководство по обновлению API ключей Firebase

## ⚠️ ВАЖНО: Ваши API ключи были раскрыты в git репозитории

Старые ключи, которые нужно заменить:
- **API Key**: `AIzaSyBa29Zw2NEbIS4BZCrMXkL1RSywLcxkfE0`
- **Client ID**: `554731795375-gd3mgpkaditm9jkb9q4da2tb5q8v27nk.apps.googleusercontent.com`

## Пошаговая инструкция

### Шаг 1: Откройте Firebase Console

1. Перейдите на https://console.firebase.google.com/
2. Войдите в свой аккаунт Google
3. Выберите проект **erudit-ai**

### Шаг 2: Обновите Firebase API Key

1. В левом меню нажмите на **⚙️ Settings** (Настройки)
2. Выберите **Project settings** (Настройки проекта)
3. Перейдите на вкладку **General** (Общие)
4. Найдите секцию **Your apps** (Ваши приложения)
5. Найдите ваше iOS приложение (Bundle ID: `com.benedikt.Erudit-AI`)
6. Нажмите на иконку **⚙️** рядом с приложением
7. Выберите **Regenerate API key** (Перегенерировать API ключ)
8. Подтвердите действие

**⚠️ Внимание:** После регенерации API ключа вам нужно будет скачать новый `GoogleService-Info.plist`

### Шаг 3: Обновите Google OAuth Client ID (если нужно)

1. В Firebase Console перейдите в **⚙️ Settings** → **Project settings**
2. Перейдите на вкладку **General**
3. Прокрутите вниз до секции **Your apps**
4. Найдите ваше iOS приложение
5. В разделе **OAuth 2.0 Client IDs** вы увидите Client ID
6. Если нужно создать новый:
   - Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
   - Выберите проект `erudit-ai`
   - Перейдите в **APIs & Services** → **Credentials**
   - Найдите OAuth 2.0 Client ID для iOS
   - При необходимости создайте новый

### Шаг 4: Скачайте новый GoogleService-Info.plist

1. В Firebase Console: **⚙️ Settings** → **Project settings**
2. Перейдите на вкладку **General**
3. В секции **Your apps** найдите ваше iOS приложение
4. Нажмите на кнопку **Download GoogleService-Info.plist**
5. Сохраните файл

### Шаг 5: Замените локальный файл

1. Откройте папку проекта: `/Users/benediktbachmetjev/Documents/Projects/erudit/frontend/`
2. **Удалите** старый файл `GoogleService-Info.plist` (если он там есть)
3. **Скопируйте** новый скачанный `GoogleService-Info.plist` в эту папку
4. Убедитесь, что файл называется точно `GoogleService-Info.plist` (без `.example`)

### Шаг 6: Проверьте, что файл не в git

Выполните в терминале:
```bash
cd /Users/benediktbachmetjev/Documents/Projects/erudit/frontend
git status
```

Файл `GoogleService-Info.plist` должен быть в списке "Untracked files" или не отображаться вообще (если он игнорируется).

### Шаг 7: Проверьте работу приложения

1. Откройте проект в Xcode
2. Соберите и запустите приложение
3. Проверьте, что Firebase и Google Sign-In работают корректно

## Альтернативный способ: Ограничение API ключа

Если вы не хотите регенерировать ключ, можно ограничить его использование:

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Выберите проект `erudit-ai`
3. Перейдите в **APIs & Services** → **Credentials**
4. Найдите API Key: `AIzaSyBa29Zw2NEbIS4BZCrMXkL1RSywLcxkfE0`
5. Нажмите на ключ для редактирования
6. В разделе **API restrictions** выберите **Restrict key**
7. Выберите только необходимые API (Firebase, Google Sign-In)
8. В разделе **Application restrictions** выберите **iOS apps**
9. Добавьте Bundle ID: `com.benedikt.Erudit-AI`
10. Сохраните изменения

Это ограничит использование ключа только вашим приложением.

## Проверка безопасности

После обновления ключей проверьте:

```bash
# Убедитесь, что файл не отслеживается git
cd /Users/benediktbachmetjev/Documents/Projects/erudit/frontend
git ls-files | grep GoogleService-Info.plist
# Должно быть пусто

# Проверьте, что файл игнорируется
git check-ignore GoogleService-Info.plist
# Должно показать: .gitignore:22:GoogleService-Info.plist
```

## Нужна помощь?

Если возникли проблемы:
1. Проверьте, что Bundle ID в Firebase совпадает с Bundle ID в Xcode
2. Убедитесь, что файл `GoogleService-Info.plist` находится в корне папки `frontend`
3. Проверьте, что файл добавлен в Xcode проект (должен быть в списке файлов проекта)

