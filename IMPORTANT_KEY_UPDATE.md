# ⚠️ ВАЖНО: Ключи все еще нужно обновить!

Ваш новый файл `GoogleService-Info.plist` содержит **старые раскрытые ключи**.

## Текущие ключи (раскрыты в git):
- **API_KEY**: `AIzaSyBa29Zw2NEbIS4BZCrMXkL1RSywLcxkfE0` ❌
- **CLIENT_ID**: `554731795375-gd3mgpkaditm9jkb9q4da2tb5q8v27nk.apps.googleusercontent.com` ❌

## Что нужно сделать СЕЙЧАС:

### Вариант 1: Регенерировать ключи в Firebase (рекомендуется)

1. Откройте **Firebase Console**: https://console.firebase.google.com/
2. Выберите проект **erudit-ai**
3. Перейдите: **⚙️ Settings** → **Project settings** → **General**
4. Найдите ваше iOS приложение
5. **Регенерируйте API ключ**:
   - Нажмите на иконку ⚙️ рядом с приложением
   - Выберите "Regenerate API key" (или "Перегенерировать")
   - Подтвердите действие
6. **Скачайте новый файл**:
   - Нажмите "Download GoogleService-Info.plist"
   - Замените старый файл новым

### Вариант 2: Ограничить использование текущих ключей

Если не хотите регенерировать (быстрее, но менее безопасно):

1. Откройте **Google Cloud Console**: https://console.cloud.google.com/
2. Выберите проект **erudit-ai**
3. Перейдите: **APIs & Services** → **Credentials**
4. Найдите API Key: `AIzaSyBa29Zw2NEbIS4BZCrMXkL1RSywLcxkfE0`
5. Нажмите на ключ для редактирования
6. Настройте ограничения:
   - **Application restrictions** → **iOS apps**
   - Добавьте Bundle ID: `com.benedikt.Erudit-AI`
   - **API restrictions** → **Restrict key** → Выберите только нужные API
7. Сохраните изменения

## После обновления:

Проверьте, что ключи изменились:
```bash
cd /Users/benediktbachmetjev/Documents/Projects/erudit/frontend
plutil -p GoogleService-Info.plist | grep API_KEY
# Должен показать НОВЫЙ ключ, не AIzaSyBa29Zw2NEbIS4BZCrMXkL1RSywLcxkfE0
```

## Почему это важно?

Старые ключи были в публичном git репозитории. Любой может использовать их для доступа к вашим Firebase ресурсам. **Обновите ключи как можно скорее!**

