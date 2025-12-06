//
//  EPUBPaginationService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import Foundation
import UIKit

/// Service for paginating text content into screen-sized pages
class EPUBPaginationService {
    
    /// Configuration for pagination
    struct PaginationConfig {
        let fontSize: CGFloat
        let lineHeight: CGFloat
        let pageInsets: UIEdgeInsets
        let font: UIFont
        
        static let `default` = PaginationConfig(
            fontSize: 18,
            lineHeight: 1.6,
            pageInsets: UIEdgeInsets(top: 40, left: 20, bottom: 100, right: 20),
            font: UIFont.systemFont(ofSize: 18)
        )
    }
    
    /// Represents a single page of content
    struct Page {
        let content: String
        let pageNumber: Int
        let isFirstPage: Bool
        let isLastPage: Bool
    }
    
    /// Paginate text content into pages based on screen size
    static func paginate(
        text: String,
        config: PaginationConfig = .default,
        pageSize: CGSize
    ) -> [Page] {
        var pages: [Page] = []
        
        // Calculate available text area
        let availableWidth = max(1, pageSize.width - config.pageInsets.left - config.pageInsets.right)
        let availableHeight = max(1, pageSize.height - config.pageInsets.top - config.pageInsets.bottom)
        
        guard availableWidth > 0 && availableHeight > 0 && !text.isEmpty else {
            // If invalid size or empty text, return single page
            return [Page(
                content: text,
                pageNumber: 1,
                isFirstPage: true,
                isLastPage: true
            )]
        }
        
        // Configure text attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = config.lineHeight
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: config.font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
        
        // Split text into pages using layout manager for accurate measurement
        var currentIndex = text.startIndex
        var pageNumber = 1
        
        print("📄 Starting pagination. Text length: \(text.count), Available size: \(availableWidth)x\(availableHeight)")
        
        while currentIndex < text.endIndex {
            // Find the end index for this page using layout manager
            let pageEndIndex = findPageEndUsingLayoutManager(
                text: text,
                startIndex: currentIndex,
                attributes: attributes,
                containerWidth: availableWidth,
                containerHeight: availableHeight
            )
            
            // Extract page content
            let pageContent = String(text[currentIndex..<pageEndIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let charactersProcessed = text.distance(from: text.startIndex, to: pageEndIndex)
            let charactersRemaining = text.distance(from: pageEndIndex, to: text.endIndex)
            
            print("📄 Page \(pageNumber): \(pageContent.count) chars, Processed: \(charactersProcessed), Remaining: \(charactersRemaining)")
            
            // Only add page if it has content
            if !pageContent.isEmpty {
                pages.append(Page(
                    content: pageContent,
                    pageNumber: pageNumber,
                    isFirstPage: pageNumber == 1,
                    isLastPage: false // Will be set later
                ))
                pageNumber += 1
            } else {
                print("⚠️ Empty page content detected, breaking")
                break
            }
            
            // Move to next page
            let previousIndex = currentIndex
            currentIndex = pageEndIndex
            
            // Check if we made progress
            if currentIndex <= previousIndex {
                print("⚠️ No progress made, breaking to prevent infinite loop")
                break
            }
            
            // Prevent infinite loop
            if currentIndex >= text.endIndex {
                print("✅ Reached end of text")
                break
            }
            
            // Safety check: ensure we're making progress
            if pageNumber > 10000 {
                print("⚠️ Too many pages, breaking to prevent infinite loop")
                break
            }
        }
        
        print("📄 Pagination complete: Created \(pages.count) pages")
        
        // Mark last page
        if let lastIndex = pages.indices.last {
            pages[lastIndex] = Page(
                content: pages[lastIndex].content,
                pageNumber: pages[lastIndex].pageNumber,
                isFirstPage: pages[lastIndex].isFirstPage,
                isLastPage: true
            )
        }
        
        // If no pages were created, create one with all text
        if pages.isEmpty {
            pages.append(Page(
                content: text,
                pageNumber: 1,
                isFirstPage: true,
                isLastPage: true
            ))
        }
        
        return pages
    }
    
    /// Find the end index for a page of text using NSLayoutManager for accurate measurement
    private static func findPageEndUsingLayoutManager(
        text: String,
        startIndex: String.Index,
        attributes: [NSAttributedString.Key: Any],
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) -> String.Index {
        // Get remaining text from start index
        let remainingText = String(text[startIndex...])
        
        guard !remainingText.isEmpty else {
            return text.endIndex
        }
        
        // Create text storage with attributed string
        let attributedText = NSMutableAttributedString(string: remainingText, attributes: attributes)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        // Create layout manager and text container
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: containerWidth, height: containerHeight))
        
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Ensure layout is calculated
        layoutManager.ensureLayout(for: textContainer)
        
        // Use binary search to find the optimal character count that fits
        var low = 0
        var high = remainingText.count
        var bestFit = 0
        
        print("🔍 Searching for page end. Text length: \(remainingText.count), Container: \(containerWidth)x\(containerHeight)")
        
        while low <= high {
            let mid = (low + high) / 2
            
            if mid == 0 {
                break
            }
            
            // Test with mid characters
            let testEndIndex = remainingText.index(remainingText.startIndex, offsetBy: mid, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
            let testText = String(remainingText[..<testEndIndex])
            
            // Create new text storage and layout manager for testing
            // Use infinite height container to measure actual text height
            let testAttributedText = NSMutableAttributedString(string: testText, attributes: attributes)
            let testTextStorage = NSTextStorage(attributedString: testAttributedText)
            let testLayoutManager = NSLayoutManager()
            let testTextContainer = NSTextContainer(size: CGSize(width: containerWidth, height: .greatestFiniteMagnitude))
            
            testTextContainer.lineFragmentPadding = 0
            testLayoutManager.addTextContainer(testTextContainer)
            testTextStorage.addLayoutManager(testLayoutManager)
            
            // Ensure layout
            testLayoutManager.ensureLayout(for: testTextContainer)
            
            // Get used rect - this gives us the actual height used
            let usedRect = testLayoutManager.usedRect(for: testTextContainer)
            
            // Check if the text fits in the available height
            if usedRect.height <= containerHeight {
                bestFit = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        print("🔍 Binary search result: bestFit = \(bestFit) characters")
        
        // If we didn't find a good fit, use fallback method
        if bestFit == 0 {
            print("⚠️ No fit found, using fallback method")
            return findPageEndUsingBoundingRect(
                text: text,
                startIndex: startIndex,
                attributes: attributes,
                containerWidth: containerWidth,
                containerHeight: containerHeight
            )
        }
        
        // Convert character count to glyph count for accurate measurement
        let testEndIndex = remainingText.index(remainingText.startIndex, offsetBy: bestFit, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
        let testText = String(remainingText[..<testEndIndex])
        
        // Create final text storage to get exact glyph range
        let finalAttributedText = NSMutableAttributedString(string: testText, attributes: attributes)
        let finalTextStorage = NSTextStorage(attributedString: finalAttributedText)
        let finalLayoutManager = NSLayoutManager()
        let finalTextContainer = NSTextContainer(size: CGSize(width: containerWidth, height: containerHeight))
        
        finalTextContainer.lineFragmentPadding = 0
        finalLayoutManager.addTextContainer(finalTextContainer)
        finalTextStorage.addLayoutManager(finalLayoutManager)
        
        finalLayoutManager.ensureLayout(for: finalTextContainer)
        
        // Get the actual character range that fits
        let glyphRange = NSRange(location: 0, length: finalLayoutManager.numberOfGlyphs)
        let characterRange = finalLayoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let characterIndex = characterRange.location + characterRange.length
        
        // Use the character index from layout manager
        let endOffset = min(characterIndex, remainingText.count)
        var endIndex = remainingText.index(remainingText.startIndex, offsetBy: endOffset, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
        
        // Try to break at word boundaries (look back up to 50 characters)
        if endIndex > remainingText.startIndex && endIndex < remainingText.endIndex {
            let lookBackDistance = min(50, remainingText.distance(from: remainingText.startIndex, to: endIndex))
            if lookBackDistance > 0 {
                let lookBackStart = remainingText.index(endIndex, offsetBy: -lookBackDistance, limitedBy: remainingText.startIndex) ?? remainingText.startIndex
                let searchRange = lookBackStart..<endIndex
                
                // Look for last space or newline
                if let lastSpace = remainingText.range(of: " ", options: .backwards, range: searchRange) {
                    endIndex = lastSpace.upperBound
                } else if let lastNewline = remainingText.range(of: "\n", options: .backwards, range: searchRange) {
                    endIndex = lastNewline.upperBound
                }
            }
        }
        
        // Convert relative index to absolute index in original text
        let relativeOffset = remainingText.distance(from: remainingText.startIndex, to: endIndex)
        return text.index(startIndex, offsetBy: relativeOffset, limitedBy: text.endIndex) ?? text.endIndex
    }
    
    /// Fallback method using boundingRect for text measurement
    private static func findPageEndUsingBoundingRect(
        text: String,
        startIndex: String.Index,
        attributes: [NSAttributedString.Key: Any],
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) -> String.Index {
        let remainingText = String(text[startIndex...])
        
        // Use binary search to find the optimal character count
        var low = 0
        var high = remainingText.count
        var bestFit = 0
        
        while low <= high {
            let mid = (low + high) / 2
            
            if mid == 0 {
                break
            }
            
            // Test with mid characters
            let testEndIndex = remainingText.index(remainingText.startIndex, offsetBy: mid, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
            let testText = String(remainingText[..<testEndIndex])
            
            // Measure this text
            let testAttributedText = NSAttributedString(string: testText, attributes: attributes)
            let boundingRect = testAttributedText.boundingRect(
                with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            if boundingRect.height <= containerHeight {
                bestFit = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        // If no good fit found, use a simple estimate
        if bestFit == 0 {
            // Estimate based on average character width and line height
            let font = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 18)
            let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
            let lineHeight = font.lineHeight * (paragraphStyle?.lineHeightMultiple ?? 1.6)
            
            let estimatedLines = Int(containerHeight / lineHeight)
            let charactersPerLine = Int(containerWidth / (font.pointSize * 0.6)) // Rough estimate
            bestFit = max(100, min(estimatedLines * charactersPerLine, remainingText.count))
        }
        
        // Find the actual end index
        let endOffset = min(bestFit, remainingText.count)
        var endIndex = remainingText.index(remainingText.startIndex, offsetBy: endOffset, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
        
        // Try to break at word boundaries
        if endIndex > remainingText.startIndex && endIndex < remainingText.endIndex {
            let lookBackDistance = min(100, remainingText.distance(from: remainingText.startIndex, to: endIndex))
            if lookBackDistance > 0 {
                let lookBackStart = remainingText.index(endIndex, offsetBy: -lookBackDistance, limitedBy: remainingText.startIndex) ?? remainingText.startIndex
                let searchRange = lookBackStart..<endIndex
                
                // Look for last space or newline
                if let lastSpace = remainingText.range(of: " ", options: .backwards, range: searchRange) {
                    endIndex = lastSpace.upperBound
                } else if let lastNewline = remainingText.range(of: "\n", options: .backwards, range: searchRange) {
                    endIndex = lastNewline.upperBound
                }
            }
        }
        
        // Convert relative index to absolute index in original text
        let relativeOffset = remainingText.distance(from: remainingText.startIndex, to: endIndex)
        return text.index(startIndex, offsetBy: relativeOffset, limitedBy: text.endIndex) ?? text.endIndex
    }
}
