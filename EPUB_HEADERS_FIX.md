# EPUB Headers Removal - Fixed

## Проблема:
В начале каждой главы появлялись заголовки H1, H2, H3 и т.д., которые мешали чтению.

## Причина:
EPUB файлы содержат HTML с заголовками глав, которые не полностью удалялись при обработке.

## Решение:

### 1. Улучшенное удаление HTML заголовков:
```swift
// Удаляем заголовки с поддержкой многострочности
cleanText = cleanText.replacingOccurrences(of: #"<h[1-6][^>]*>.*?</h[1-6]>"#, with: "", 
    options: [.regularExpression, .caseInsensitive, .dotMatchesLineSeparators])

// Удаляем открывающие теги заголовков
cleanText = cleanText.replacingOccurrences(of: #"<h[1-6][^>]*>"#, with: "", 
    options: [.regularExpression, .caseInsensitive])

// Удаляем закрывающие теги заголовков  
cleanText = cleanText.replacingOccurrences(of: #"</h[1-6]>"#, with: "", 
    options: [.regularExpression, .caseInsensitive])
```

### 2. Фильтрация коротких строк:
```swift
// Удаляем строки, которые выглядят как заголовки глав
let lines = cleanText.components(separatedBy: .newlines)
let cleanedLines = lines.filter { line in
    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
    // Оставляем только длинные строки или строки со строчными буквами
    return trimmedLine.count > 20 || trimmedLine.rangeOfCharacter(from: .lowercaseLetters) != nil
}
```

### 3. Улучшенная обработка CSS и JavaScript:
```swift
// Добавлен .dotMatchesLineSeparators для многострочных блоков
cleanText = cleanText.replacingOccurrences(of: #"<style[^>]*>.*?</style>"#, with: "", 
    options: [.regularExpression, .caseInsensitive, .dotMatchesLineSeparators])
```

## Результат:
- ✅ Заголовки H1-H6 полностью удаляются
- ✅ Короткие строки (заголовки глав) фильтруются
- ✅ Остается только основной текст для чтения
- ✅ Улучшена обработка многострочных HTML блоков

## Что это означает:
Теперь в EPUB книгах вы будете видеть только чистый текст без заголовков глав, что делает чтение более комфортным.







