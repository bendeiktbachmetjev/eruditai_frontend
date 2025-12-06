//
//  FlashCardEditView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import FirebaseAuth

/// View for creating and editing flashcards
struct FlashCardEditView: View {
    let flashcard: Flashcard?
    let onSave: (Flashcard) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var highlightText: String = ""
    @State private var bookTitle: String = ""
    @State private var isCreating: Bool = false
    
    init(flashcard: Flashcard?, onSave: @escaping (Flashcard) -> Void) {
        self.flashcard = flashcard
        self.onSave = onSave
        
        // Initialize state with existing flashcard data
        if let flashcard = flashcard {
            _question = State(initialValue: flashcard.question)
            _answer = State(initialValue: flashcard.answer)
            _highlightText = State(initialValue: flashcard.highlightText)
            _bookTitle = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Flashcard Content")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                        
                        TextField("Enter your question...", text: $question, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer")
                            .font(.headline)
                        
                        TextField("Enter the answer...", text: $answer, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...8)
                    }
                }
                
                Section(header: Text("Source Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlighted Text")
                            .font(.headline)
                        
                        TextField("Text that was highlighted...", text: $highlightText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                            .disabled(true) // Usually filled automatically
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Book Title")
                            .font(.headline)
                        
                        TextField("Book title...", text: $bookTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                if flashcard != nil {
                    Section(header: Text("Statistics")) {
                        HStack {
                            Text("Created:")
                            Spacer()
                            Text(flashcard?.createdAt ?? Date(), style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Repetitions:")
                            Spacer()
                            Text("\(flashcard?.repetitions ?? 0)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Next Review:")
                            Spacer()
                            if let nextReview = flashcard?.nextReview {
                                Text(nextReview, style: .date)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Due now")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle(flashcard == nil ? "New Flashcard" : "Edit Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFlashcard()
                    }
                    .disabled(question.isEmpty || answer.isEmpty || isCreating)
                }
            }
        }
        .onAppear {
            if let flashcard = flashcard {
                // Extract book title from highlight text if available
                if bookTitle.isEmpty && !flashcard.highlightText.isEmpty {
                    // Try to extract book title from context
                    bookTitle = "Unknown Book"
                }
            }
        }
    }
    
    private func saveFlashcard() {
        guard !question.isEmpty && !answer.isEmpty else { return }
        
        isCreating = true
        
        let userId = Auth.auth().currentUser?.uid ?? ""
        
        let flashcardToSave: Flashcard
        if let existingFlashcard = flashcard {
            // Update existing flashcard
            flashcardToSave = existingFlashcard.copyWith(
                question: question,
                answer: answer,
                highlightText: highlightText.isEmpty ? existingFlashcard.highlightText : highlightText
            )
        } else {
            // Create new flashcard
            flashcardToSave = Flashcard(
                id: UUID().uuidString,
                question: question,
                answer: answer,
                createdAt: Date(),
                bookId: "", // Will be set when saving
                highlightText: highlightText,
                userId: userId
            )
        }
        
        onSave(flashcardToSave)
        presentationMode.wrappedValue.dismiss()
    }
}

/// Preview for creating new flashcard
struct FlashCardEditView_Create: View {
    @State private var showingEditView = false
    
    var body: some View {
        VStack {
            Button("Create New Flashcard") {
                showingEditView = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingEditView) {
            FlashCardEditView(flashcard: nil) { newFlashcard in
                print("Created flashcard: \(newFlashcard.question)")
            }
        }
    }
}

/// Preview for editing existing flashcard
struct FlashCardEditView_Edit: View {
    @State private var showingEditView = false
    
    private let sampleFlashcard = Flashcard(
        id: "test",
        question: "What is the capital of France?",
        answer: "Paris",
        createdAt: Date(),
        bookId: "book1",
        highlightText: "Paris is the capital and largest city of France.",
        userId: "user1"
    )
    
    var body: some View {
        VStack {
            Button("Edit Flashcard") {
                showingEditView = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingEditView) {
            FlashCardEditView(flashcard: sampleFlashcard) { updatedFlashcard in
                print("Updated flashcard: \(updatedFlashcard.question)")
            }
        }
    }
}

#Preview("Create") {
    FlashCardEditView_Create()
}

#Preview("Edit") {
    FlashCardEditView_Edit()
}







