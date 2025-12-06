# Simple Flashcard Generation System

## Overview
Упрощенная система генерации флешкарт из выделенного текста с использованием только Railway API.

## Features
- **Простое выделение текста**: В EPUB и PDF
- **Одна кнопка**: "Generate Flashcard" появляется при выделении текста
- **Автоматическое сохранение**: Флешкарты сохраняются в Firebase
- **Только Railway API**: Никаких сложных конфигураций

## Как работает

### EPUB книги
1. Выделите текст в EPUB читателе
2. Появится кнопка "Generate Flashcard"
3. Нажмите кнопку - флешкарта создается и сохраняется

### PDF книги
1. Долго нажмите на текст в PDF (long press)
2. Появится кнопка "Generate Flashcard"
3. Нажмите кнопку - флешкарта создается и сохраняется

## Архитектура

### Services
- **SimpleFlashcardService**: Единственный сервис для генерации флешкарт
- **AIService**: Существующий Railway API сервис
- **FlashcardService**: Существующий Firebase сервис

### Views
- **SimpleFlashcardButton**: Простая плавающая кнопка
- **EPUBWebViewWithHighlighting**: EPUB с выделением текста
- **PDFWebViewWithHighlighting**: PDF с выделением текста

## Использование

```swift
// Генерация флешкарты
let flashcards = try await SimpleFlashcardService.shared.generateAndSaveFlashcards(
    highlightedText: "Выделенный текст",
    bookTitle: "Название книги",
    bookId: "id-книги",
    count: 1
)
```

## Технические детали

### EPUB выделение текста
- Использует JavaScript для отслеживания выделения
- Автоматически показывает кнопку при выделении

### PDF выделение текста
- Использует UILongPressGestureRecognizer
- PDFKit selectionForRect для получения текста
- Минимум 3 символа для активации

### Railway API
- Endpoint: `https://eruditai-production.up.railway.app/api/generate-flashcards`
- Генерирует 1 флешкарту за раз
- Автоматически сохраняет в Firebase

## Преимущества упрощенной системы
- ✅ Простота использования
- ✅ Одна кнопка - один клик
- ✅ Работает с EPUB и PDF
- ✅ Автоматическое сохранение
- ✅ Никаких настроек API ключей
- ✅ Минимальный код

