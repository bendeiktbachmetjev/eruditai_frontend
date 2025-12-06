# GPT Flashcard Service Integration

## Overview
This implementation adds GPT-powered flashcard generation to the Erudit AI app. Users can now select text while reading books and generate flashcards automatically using either OpenAI GPT or Railway API.

## Features
- **Text Selection**: Select text in both PDF and EPUB readers
- **AI Generation**: Generate flashcards using OpenAI GPT-4 or Railway API
- **Firebase Integration**: Save flashcards to Firebase with user authentication
- **Spaced Repetition**: Built-in spaced repetition algorithm support
- **Universal API**: Automatically chooses the best available API

## Setup Instructions

### 1. OpenAI API Configuration
1. Get your OpenAI API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open `APIConfiguration.swift`
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key:

```swift
static let openAIAPIKey = "sk-your-actual-api-key-here"
```

### 2. Firebase Configuration
Ensure your Firebase project is properly configured:
- Firebase Authentication is enabled
- Firestore database is set up
- `GoogleService-Info.plist` is added to the project

### 3. API Selection
The app automatically chooses the best available API:
- **OpenAI GPT-4**: If API key is configured (preferred)
- **Railway API**: Fallback option (existing implementation)

## Architecture

### Services
- **GPTService**: Direct OpenAI GPT-4 integration
- **UniversalFlashcardService**: Smart API selection and management
- **GPTFlashcardService**: Firebase integration for GPT-generated flashcards
- **FlashcardService**: Existing Firebase flashcard management

### Views
- **FlashcardGeneratorView**: UI for generating and previewing flashcards
- **EPUBWebViewWithHighlighting**: EPUB reader with text selection
- **PDFWebViewWithHighlighting**: PDF reader with text selection

### Models
- **Flashcard**: Enhanced with spaced repetition algorithm
- **APIConfiguration**: Centralized API configuration

## Usage

### For Users
1. Open any book (PDF or EPUB)
2. Select text by tapping and dragging
3. Tap "Generate Flashcards" when the generator appears
4. Review generated flashcards
5. Save to your flashcard collection

### For Developers
```swift
// Generate flashcards programmatically
let flashcards = try await UniversalFlashcardService.shared.generateAndSaveFlashcards(
    highlightedText: "Selected text",
    bookTitle: "Book Title",
    bookId: "book-id",
    count: 3
)
```

## API Endpoints

### OpenAI GPT-4
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Model**: `gpt-4`
- **Authentication**: Bearer token

### Railway (Fallback)
- **Endpoint**: `https://eruditai-production.up.railway.app/api/generate-flashcards`
- **Method**: POST
- **Authentication**: None required

## Error Handling
The implementation includes comprehensive error handling for:
- Network connectivity issues
- API rate limits
- Invalid responses
- Authentication failures
- Firebase connection problems

## Testing
Test the connection using:
```swift
let isConnected = await UniversalFlashcardService.shared.testConnection()
```

## Security Notes
- API keys are stored in code (consider using environment variables for production)
- User authentication is handled through Firebase
- All user data is stored securely in Firestore

## Future Enhancements
- Environment-based API key management
- Offline flashcard generation
- Batch text processing
- Custom prompt templates
- Multi-language support

