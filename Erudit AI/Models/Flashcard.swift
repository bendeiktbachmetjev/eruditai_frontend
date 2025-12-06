//
//  Flashcard.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import FirebaseFirestore

/// Model for flashcard with Spaced Repetition Algorithm support
struct Flashcard: Identifiable, Codable {
    let id: String
    let question: String
    let answer: String
    let createdAt: Date
    let bookId: String
    let highlightText: String
    let userId: String
    let lastReviewed: Date?
    let nextReview: Date?
    let interval: Int // days until next review
    let easeFactor: Double // difficulty multiplier (1.3 - 2.5)
    let repetitions: Int // consecutive successful reviews
    
    init(
        id: String,
        question: String,
        answer: String,
        createdAt: Date,
        bookId: String,
        highlightText: String,
        userId: String,
        lastReviewed: Date? = nil,
        nextReview: Date? = nil,
        interval: Int = 1,
        easeFactor: Double = 2.5,
        repetitions: Int = 0
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
        self.bookId = bookId
        self.highlightText = highlightText
        self.userId = userId
        self.lastReviewed = lastReviewed
        self.nextReview = nextReview
        self.interval = interval
        self.easeFactor = easeFactor
        self.repetitions = repetitions
    }
    
    /// Check if flashcard is due for review
    var isDue: Bool {
        guard let nextReview = nextReview else { return true }
        return Date() >= nextReview
    }
    
    /// Get days until next review
    var daysUntilReview: Int {
        guard let nextReview = nextReview else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: nextReview)
        return max(0, components.day ?? 0)
    }
    
    /// Create a copy with updated values
    func copyWith(
        id: String? = nil,
        question: String? = nil,
        answer: String? = nil,
        createdAt: Date? = nil,
        bookId: String? = nil,
        highlightText: String? = nil,
        userId: String? = nil,
        lastReviewed: Date? = nil,
        nextReview: Date? = nil,
        interval: Int? = nil,
        easeFactor: Double? = nil,
        repetitions: Int? = nil
    ) -> Flashcard {
        return Flashcard(
            id: id ?? self.id,
            question: question ?? self.question,
            answer: answer ?? self.answer,
            createdAt: createdAt ?? self.createdAt,
            bookId: bookId ?? self.bookId,
            highlightText: highlightText ?? self.highlightText,
            userId: userId ?? self.userId,
            lastReviewed: lastReviewed ?? self.lastReviewed,
            nextReview: nextReview ?? self.nextReview,
            interval: interval ?? self.interval,
            easeFactor: easeFactor ?? self.easeFactor,
            repetitions: repetitions ?? self.repetitions
        )
    }
}

// MARK: - Firebase Support
extension Flashcard {
    /// Convert to Firestore document
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "question": question,
            "answer": answer,
            "createdAt": Timestamp(date: createdAt),
            "bookId": bookId,
            "highlightText": highlightText,
            "userId": userId,
            "interval": interval,
            "easeFactor": easeFactor,
            "repetitions": repetitions
        ]
        
        if let lastReviewed = lastReviewed {
            data["lastReviewed"] = Timestamp(date: lastReviewed)
        }
        
        if let nextReview = nextReview {
            data["nextReview"] = Timestamp(date: nextReview)
        }
        
        return data
    }
    
    /// Create from Firestore document
    static func fromFirestore(id: String, data: [String: Any]) -> Flashcard? {
        guard let question = data["question"] as? String,
              let answer = data["answer"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let bookId = data["bookId"] as? String,
              let highlightText = data["highlightText"] as? String,
              let userId = data["userId"] as? String else {
            return nil
        }
        
        let lastReviewed = (data["lastReviewed"] as? Timestamp)?.dateValue()
        let nextReview = (data["nextReview"] as? Timestamp)?.dateValue()
        let interval = data["interval"] as? Int ?? 1
        let easeFactor = (data["easeFactor"] as? Double) ?? 2.5
        let repetitions = data["repetitions"] as? Int ?? 0
        
        return Flashcard(
            id: id,
            question: question,
            answer: answer,
            createdAt: createdAtTimestamp.dateValue(),
            bookId: bookId,
            highlightText: highlightText,
            userId: userId,
            lastReviewed: lastReviewed,
            nextReview: nextReview,
            interval: interval,
            easeFactor: easeFactor,
            repetitions: repetitions
        )
    }
}

// MARK: - Spaced Repetition Algorithm
extension Flashcard {
    /// Calculate next review using Spaced Repetition Algorithm
    static func calculateNextReview(_ flashcard: Flashcard, quality: Int) -> Flashcard {
        let now = Date()
        
        if quality <= 1 {
            // Complete blackout or very poor: immediate short retry
            return flashcard.copyWith(
                lastReviewed: now,
                nextReview: now.addingTimeInterval(5 * 60), // 5 minutes
                interval: 0,
                easeFactor: calculateEaseFactor(flashcard.easeFactor, quality: quality),
                repetitions: 0
            )
        }
        
        if quality == 2 {
            // Hard: retry later today
            return flashcard.copyWith(
                lastReviewed: now,
                nextReview: now.addingTimeInterval(10 * 60 * 60), // 10 hours
                interval: 0,
                easeFactor: calculateEaseFactor(flashcard.easeFactor, quality: quality),
                repetitions: flashcard.repetitions // do not advance
            )
        }
        
        // Successful review (3..5)
        let newRepetitions = flashcard.repetitions + 1
        let newIntervalDays: Int
        
        if newRepetitions == 1 {
            newIntervalDays = 1 // first successful day interval
        } else if newRepetitions == 2 {
            newIntervalDays = 6 // second successful interval like SM-2
        } else {
            newIntervalDays = Int(Double(flashcard.interval) * flashcard.easeFactor)
                .clamped(to: 1...3650)
        }
        
        let newEaseFactor = calculateEaseFactor(flashcard.easeFactor, quality: quality)
        
        return flashcard.copyWith(
            lastReviewed: now,
            nextReview: now.addingTimeInterval(TimeInterval(newIntervalDays * 24 * 60 * 60)),
            interval: newIntervalDays,
            easeFactor: newEaseFactor,
            repetitions: newRepetitions
        )
    }
    
    /// Calculate ease factor based on quality
    private static func calculateEaseFactor(_ currentEaseFactor: Double, quality: Int) -> Double {
        let newEaseFactor = currentEaseFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        return newEaseFactor.clamped(to: 1.3...2.5)
    }
}

// MARK: - Helper Extensions
extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}