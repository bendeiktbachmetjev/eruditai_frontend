//
//  EPUBService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import Foundation
import EPUBKit
import UIKit
import ZIPFoundation

/// Service for parsing EPUB files and extracting content
class EPUBService {
    
    /// Parse EPUB file and extract all text content
    static func parseEPUB(filePath: String) async throws -> String {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw EPUBError.fileNotFound(filePath)
        }
        
        guard FileManager.default.isReadableFile(atPath: filePath) else {
            throw EPUBError.fileNotReadable(filePath)
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Parse EPUB using EPUBKit
        guard let document = EPUBDocument(url: fileURL) else {
            throw EPUBError.invalidContainer
        }
        
        // Extract EPUB to temporary directory once
        let tempDir = try await extractEPUB(epubURL: fileURL)
        
        defer {
            // Clean up temp directory after we're done
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract full text content from all chapters
        let fullText = try await extractFullText(
            from: document,
            tempDir: tempDir
        )
        
        return fullText
    }
    
    /// Extract EPUB to temporary directory
    private static func extractEPUB(epubURL: URL) async throws -> URL {
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Extract EPUB (ZIP archive)
        guard let archive = Archive(url: epubURL, accessMode: .read) else {
            throw EPUBError.invalidContainer
        }
        
        // Extract all entries
        for entry in archive {
            let entryURL = tempDir.appendingPathComponent(entry.path)
            let entryDir = entryURL.deletingLastPathComponent()
            
            try FileManager.default.createDirectory(at: entryDir, withIntermediateDirectories: true)
            _ = try archive.extract(entry, to: entryURL)
        }
        
        return tempDir
    }
    
    /// Extract full text content from EPUB document in reading order
    private static func extractFullText(
        from document: EPUBDocument,
        tempDir: URL
    ) async throws -> String {
        var fullText = ""
        
        // Iterate through spine items (reading order)
        for spineItem in document.spine.items {
            // Get manifest item for this spine item
            guard let manifestItem = document.manifest.items[spineItem.idref] else {
                continue
            }
            
            // Skip if not HTML/XHTML content
            // Check file extension instead of mediaType to avoid type conversion issues
            let filePath = manifestItem.path.lowercased()
            guard filePath.hasSuffix(".html") || 
                  filePath.hasSuffix(".xhtml") || 
                  filePath.hasSuffix(".htm") else {
                continue
            }
            
            // Read chapter content from extracted files
            let chapterPath = manifestItem.path
            let chapterContent = try readChapterFromExtractedFiles(
                chapterPath: chapterPath,
                tempDir: tempDir
            )
            
            if let content = chapterContent {
                // Extract text from HTML
                let text = extractTextFromHTML(content)
                if !fullText.isEmpty && !text.isEmpty {
                    fullText += "\n\n"
                }
                fullText += text
            }
        }
        
        return fullText
    }
    
    /// Read chapter content from extracted files
    private static func readChapterFromExtractedFiles(
        chapterPath: String,
        tempDir: URL
    ) throws -> String? {
        // Try different path variations
        let possiblePaths = [
            chapterPath,
            "/" + chapterPath,
            chapterPath.replacingOccurrences(of: "\\", with: "/"),
            (chapterPath as NSString).lastPathComponent
        ]
        
        for path in possiblePaths {
            let fileURL = tempDir.appendingPathComponent(path)
            
            // Check if file exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Read file content
                let data = try Data(contentsOf: fileURL)
                
                // Try different encodings
                if let content = String(data: data, encoding: .utf8) {
                    return content
                } else if let content = String(data: data, encoding: .utf16) {
                    return content
                } else if let content = String(data: data, encoding: .windowsCP1251) {
                    return content
                }
            }
        }
        
        // If not found by path, search for file by name
        let fileName = (chapterPath as NSString).lastPathComponent
        if let foundURL = findFileByName(fileName, in: tempDir) {
            let data = try Data(contentsOf: foundURL)
            if let content = String(data: data, encoding: .utf8) {
                return content
            }
        }
        
        return nil
    }
    
    /// Find file by name in directory recursively
    private static func findFileByName(_ fileName: String, in directory: URL) -> URL? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return nil
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == fileName {
                return fileURL
            }
        }
        
        return nil
    }
    
    /// Extract plain text from HTML content
    private static func extractTextFromHTML(_ html: String) -> String {
        var text = html
        
        // Remove script tags using NSRegularExpression for multiline support
        do {
            let scriptRegex = try NSRegularExpression(pattern: #"<script[^>]*>.*?</script>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.utf16.count)
            text = scriptRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            // Fallback to simple replacement if regex fails
            text = text.replacingOccurrences(of: #"<script[^>]*>.*?</script>"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove style tags
        do {
            let styleRegex = try NSRegularExpression(pattern: #"<style[^>]*>.*?</style>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.utf16.count)
            text = styleRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            text = text.replacingOccurrences(of: #"<style[^>]*>.*?</style>"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove HTML comments
        do {
            let commentRegex = try NSRegularExpression(pattern: #"<!--.*?-->"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.utf16.count)
            text = commentRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            text = text.replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove head section
        do {
            let headRegex = try NSRegularExpression(pattern: #"<head[^>]*>.*?</head>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.utf16.count)
            text = headRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            text = text.replacingOccurrences(of: #"<head[^>]*>.*?</head>"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Replace paragraph tags with newlines
        text = text.replacingOccurrences(
            of: #"<p[^>]*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "</p>", with: "\n\n")
        
        // Replace break tags with newlines
        text = text.replacingOccurrences(
            of: #"<br[^>]*/?>"#,
            with: "\n",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // Replace div tags
        text = text.replacingOccurrences(
            of: #"<div[^>]*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "</div>", with: "\n")
        
        // Replace section tags
        text = text.replacingOccurrences(
            of: #"<section[^>]*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "</section>", with: "\n")
        
        // Remove heading tags (but preserve their content)
        text = text.replacingOccurrences(
            of: #"<h[1-6][^>]*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(
            of: #"</h[1-6]>"#,
            with: "\n\n",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // Remove all remaining HTML tags
        text = text.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: "",
            options: .regularExpression
        )
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        text = text.replacingOccurrences(of: "&mdash;", with: "—")
        text = text.replacingOccurrences(of: "&ndash;", with: "–")
        text = text.replacingOccurrences(of: "&hellip;", with: "…")
        text = text.replacingOccurrences(of: "&ldquo;", with: "\u{201C}")
        text = text.replacingOccurrences(of: "&rdquo;", with: "\u{201D}")
        text = text.replacingOccurrences(of: "&lsquo;", with: "'")
        text = text.replacingOccurrences(of: "&rsquo;", with: "'")
        
        // Clean up whitespace
        text = text.replacingOccurrences(
            of: #"\n\s*\n\s*\n+"#,
            with: "\n\n",
            options: .regularExpression
        )
        
        // Remove leading/trailing whitespace from each line
        let lines = text.components(separatedBy: .newlines)
        let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        text = cleanedLines.joined(separator: "\n")
        
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
}

/// EPUB-specific errors
enum EPUBError: Error, LocalizedError {
    case fileNotFound(String)
    case fileNotReadable(String)
    case invalidContainer
    case invalidOPF
    case chapterNotFound
    case extractionFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "EPUB file not found at path: \(path)"
        case .fileNotReadable(let path):
            return "EPUB file is not readable at path: \(path)"
        case .invalidContainer:
            return "Invalid EPUB container format"
        case .invalidOPF:
            return "Invalid OPF file"
        case .chapterNotFound:
            return "Chapter not found"
        case .extractionFailed:
            return "Failed to extract EPUB content"
        }
    }
}
