//
//  EPUBWebViewWithHighlighting.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import WebKit
import Foundation
import PDFKit

/// EPUB WebView with text highlighting and flashcard generation capabilities
struct EPUBWebViewWithHighlighting: UIViewRepresentable {
    let htmlContent: String
    let book: Book
    @Binding var selectedText: String
    @Binding var showFlashcardGenerator: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        
        // Configure for better text selection
        webView.allowsLinkPreview = false
        webView.scrollView.bounces = true
        webView.scrollView.isScrollEnabled = true
        webView.isUserInteractionEnabled = true
        
        // Enable text selection
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add JavaScript for text selection handling
        let script = """
        let selectionTimeout;
        let lastSelectedText = '';
        
        // Prevent default text selection behavior that might interfere
        document.addEventListener('selectstart', function(e) {
            // Allow text selection
            return true;
        });
        
        // Handle mouse up event for better selection detection
        document.addEventListener('mouseup', function(e) {
            setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                if (selectedText.length > 3 && selectedText !== lastSelectedText) {
                    lastSelectedText = selectedText;
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: selectedText
                    });
                } else if (selectedText.length === 0) {
                    // Clear selection if clicking on empty space
                    lastSelectedText = '';
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: ''
                    });
                }
            }, 100);
        });
        
        // Also listen to selection change as backup
        document.addEventListener('selectionchange', function() {
            clearTimeout(selectionTimeout);
            selectionTimeout = setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                if (selectedText.length > 3 && selectedText !== lastSelectedText) {
                    lastSelectedText = selectedText;
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: selectedText
                    });
                }
            }, 200);
        });
        
        // Add highlighting styles and improve text selection
        const style = document.createElement('style');
        style.textContent = `
            ::selection {
                background-color: rgba(0, 123, 255, 0.3) !important;
            }
            * {
                -webkit-user-select: text !important;
                -moz-user-select: text !important;
                -ms-user-select: text !important;
                user-select: text !important;
            }
            .highlighted {
                background-color: rgba(255, 193, 7, 0.3);
                border-radius: 3px;
                padding: 1px 2px;
            }
        `;
        document.head.appendChild(style);
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Add message handler for text selection
        webView.configuration.userContentController.add(context.coordinator, name: "textSelection")
        
        // Add long press gesture as alternative selection method
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        webView.addGestureRecognizer(longPressGesture)
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: EPUBWebViewWithHighlighting
        
        init(_ parent: EPUBWebViewWithHighlighting) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "textSelection" {
                if let body = message.body as? [String: Any],
                   let text = body["text"] as? String {
                    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    DispatchQueue.main.async {
                        if cleanText.isEmpty {
                            // Clear selection
                            self.parent.selectedText = ""
                            self.parent.showFlashcardGenerator = false
                        } else if cleanText != self.parent.selectedText && cleanText.count > 3 {
                            // Update with new selection
                            self.parent.selectedText = cleanText
                            self.parent.showFlashcardGenerator = true
                        }
                    }
                }
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let webView = gesture.view as? WKWebView else { return }
            
            if gesture.state == .began {
                let point = gesture.location(in: webView)
                
                // Use JavaScript to get text at the point
                let script = """
                function getTextAtPoint(x, y) {
                    const element = document.elementFromPoint(x, y);
                    if (element) {
                        const text = element.textContent || element.innerText || '';
                        return text.trim();
                    }
                    return '';
                }
                getTextAtPoint(\(point.x), \(point.y));
                """
                
                webView.evaluateJavaScript(script) { result, error in
                    if let text = result as? String, !text.isEmpty && text.count > 3 {
                        DispatchQueue.main.async {
                            self.parent.selectedText = text
                            self.parent.showFlashcardGenerator = true
                        }
                    }
                }
            }
        }
    }
}

/// PDF WebView with text highlighting and flashcard generation capabilities
struct PDFWebViewWithHighlighting: UIViewRepresentable {
    let pdfDocument: PDFKit.PDFDocument
    @Binding var selectedText: String
    @Binding var showFlashcardGenerator: Bool
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        
        // Enable text selection
        pdfView.isInMarkupMode = false
        
        // Add notification observer for text selection changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFWebViewWithHighlighting
        
        init(_ parent: PDFWebViewWithHighlighting) {
            self.parent = parent
        }
        
        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let selection = pdfView.currentSelection else { return }
            
            let selectedText = selection.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if !selectedText.isEmpty && selectedText.count > 3 {
                DispatchQueue.main.async {
                    self.parent.selectedText = selectedText
                    self.parent.showFlashcardGenerator = true
                }
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
