//
//  BookReaderView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import PDFKit
import WebKit
import UniformTypeIdentifiers
import Foundation

struct BookReaderView: View {
    let book: Book
    @State private var pdfDocument: PDFKit.PDFDocument?
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Error Loading Book")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if book.isPDF {
                PDFReaderView(book: book, pdfDocument: pdfDocument)
            } else if book.isEPUB {
                EPUBPaginationReaderView(book: book)
            } else {
                UnsupportedFileView()
            }
        }
        .onAppear {
            if book.isPDF {
                loadPDF()
            }
        }
    }
    
    private func loadPDF() {
        guard let filePath = book.filePath else {
            errorMessage = "File path is missing"
            return
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            errorMessage = "File not found at path: \(filePath)"
            return
        }
        
        if let pdfDoc = PDFKit.PDFDocument(url: url) {
            self.pdfDocument = pdfDoc
        } else {
            errorMessage = "Failed to load PDF from \(filePath)"
        }
    }
}

// MARK: - PDF Reader View
struct PDFReaderView: View {
    let book: Book
    let pdfDocument: PDFKit.PDFDocument?
    @State private var currentPage: Int = 0
    @State private var selectedText = ""
    @State private var showFlashcardGenerator = false
    
    var body: some View {
        ZStack {
            if let pdfDoc = pdfDocument {
                PDFWebViewWithHighlighting(
                    pdfDocument: pdfDoc,
                    selectedText: $selectedText,
                    showFlashcardGenerator: $showFlashcardGenerator
                )
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading PDF...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            SimpleFlashcardButton(
                selectedText: selectedText,
                book: book,
                isVisible: $showFlashcardGenerator
            )
        )
    }
}

// MARK: - PDFKit View Wrapper
struct PDFKitView: UIViewRepresentable {
    let document: PDFKit.PDFDocument
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        
        if let page = document.page(at: min(currentPage, document.pageCount - 1)) {
            pdfView.go(to: page)
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
    }
}


// MARK: - Unsupported File View
struct UnsupportedFileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Unsupported File Type")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This file type is not supported yet")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        BookReaderView(
            book: Book(
                id: "test",
                title: "Sample PDF",
                author: "Test Author",
                coverUrl: "",
                openedAt: Date(),
                filePath: nil,
                fileType: "pdf",
                lastReadPage: 0
            )
        )
    }
}
