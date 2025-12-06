//
//  TextSelectionTestView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import WebKit

/// Test view for debugging text selection
struct TextSelectionTestView: View {
    @State private var selectedText = ""
    @State private var showFlashcardGenerator = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Text Selection Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Try selecting text below:")
                .font(.headline)
            
            TextSelectionWebView(
                htmlContent: createTestHTML(),
                selectedText: $selectedText,
                showFlashcardGenerator: $showFlashcardGenerator
            )
            .frame(height: 400)
            .border(Color.gray, width: 1)
            
            if !selectedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Text:")
                        .font(.headline)
                    Text(selectedText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if showFlashcardGenerator {
                Button("Generate Flashcard") {
                    print("📱 Generating flashcard for: \(selectedText)")
                    showFlashcardGenerator = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func createTestHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
            <style>
                * {
                    -webkit-user-select: text !important;
                    user-select: text !important;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 18px;
                    line-height: 1.6;
                    padding: 20px;
                    -webkit-user-select: text !important;
                    user-select: text !important;
                }
                p {
                    margin-bottom: 15px;
                    -webkit-user-select: text !important;
                    user-select: text !important;
                }
                ::selection {
                    background-color: rgba(0, 123, 255, 0.3) !important;
                }
            </style>
        </head>
        <body>
            <h1>Test Document</h1>
            <p>This is a test paragraph with some text that you can try to select. The text should be selectable and when you select it, a button should appear.</p>
            <p>Here is another paragraph with more text. Try selecting different parts of this text to test the functionality.</p>
            <p>This is the third paragraph. You can select single words, multiple words, or entire sentences. The selection should work smoothly.</p>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
        </body>
        </html>
        """
    }
}

// MARK: - Text Selection WebView
struct TextSelectionWebView: UIViewRepresentable {
    let htmlContent: String
    @Binding var selectedText: String
    @Binding var showFlashcardGenerator: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Configure WebView for text selection
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.allowsLinkPreview = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = true
        
        // Enable text selection
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add JavaScript for text selection
        let script = """
        console.log('Text Selection Script Loaded');
        
        let selectionTimeout;
        let lastSelectedText = '';
        let isSelecting = false;
        
        // Force enable text selection on all elements
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM Content Loaded');
            
            // Apply text selection styles to all elements
            const style = document.createElement('style');
            style.textContent = `
                * {
                    -webkit-user-select: text !important;
                    -moz-user-select: text !important;
                    -ms-user-select: text !important;
                    user-select: text !important;
                    -webkit-touch-callout: default !important;
                }
                ::selection {
                    background-color: rgba(0, 123, 255, 0.3) !important;
                }
                body {
                    -webkit-user-select: text !important;
                    user-select: text !important;
                }
            `;
            document.head.appendChild(style);
            
            // Make sure all text elements are selectable
            const allElements = document.querySelectorAll('*');
            allElements.forEach(element => {
                element.style.webkitUserSelect = 'text';
                element.style.userSelect = 'text';
            });
        });
        
        // Handle text selection start
        document.addEventListener('selectstart', function(e) {
            console.log('Selection started');
            isSelecting = true;
            return true;
        });
        
        // Handle mouse up - main selection handler
        document.addEventListener('mouseup', function(e) {
            console.log('Mouse up');
            
            setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                console.log('Selected text:', selectedText, 'Length:', selectedText.length);
                
                if (selectedText.length > 3 && selectedText !== lastSelectedText) {
                    console.log('Sending text to native:', selectedText);
                    lastSelectedText = selectedText;
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: selectedText,
                        action: 'select'
                    });
                } else if (selectedText.length === 0) {
                    console.log('Clearing selection');
                    lastSelectedText = '';
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: '',
                        action: 'clear'
                    });
                }
                
                isSelecting = false;
            }, 150);
        });
        
        // Handle touch events for mobile
        document.addEventListener('touchend', function(e) {
            console.log('Touch end');
            
            setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                console.log('Touch selected text:', selectedText);
                
                if (selectedText.length > 3 && selectedText !== lastSelectedText) {
                    console.log('Sending touch text to native:', selectedText);
                    lastSelectedText = selectedText;
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: selectedText,
                        action: 'select'
                    });
                }
            }, 200);
        });
        
        // Backup selection change handler
        document.addEventListener('selectionchange', function() {
            if (!isSelecting) return;
            
            clearTimeout(selectionTimeout);
            selectionTimeout = setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                console.log('Selection change:', selectedText);
                
                if (selectedText.length > 3 && selectedText !== lastSelectedText) {
                    lastSelectedText = selectedText;
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: selectedText,
                        action: 'select'
                    });
                }
            }, 300);
        });
        
        // Handle clicks to clear selection
        document.addEventListener('click', function(e) {
            console.log('Document clicked');
            
            setTimeout(function() {
                const selection = window.getSelection();
                const selectedText = selection.toString().trim();
                
                if (selectedText.length === 0) {
                    console.log('Click cleared selection');
                    lastSelectedText = '';
                    window.webkit.messageHandlers.textSelection.postMessage({
                        text: '',
                        action: 'clear'
                    });
                }
            }, 100);
        });
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Add message handler
        webView.configuration.userContentController.add(context.coordinator, name: "textSelection")
        
        // Load the HTML content
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload when content changes
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        // Clear selection when content changes
        DispatchQueue.main.async {
            selectedText = ""
            showFlashcardGenerator = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: TextSelectionWebView
        
        init(_ parent: TextSelectionWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("📱 Received message from JavaScript: \(message.body)")
            
            if message.name == "textSelection" {
                if let body = message.body as? [String: Any],
                   let text = body["text"] as? String,
                   let action = body["action"] as? String {
                    
                    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    print("📱 Processed text: '\(cleanText)' Action: \(action)")
                    
                    DispatchQueue.main.async {
                        if action == "clear" {
                            print("📱 Clearing selection")
                            self.parent.selectedText = ""
                            self.parent.showFlashcardGenerator = false
                        } else if action == "select" && cleanText.count > 3 {
                            print("📱 Setting selection: '\(cleanText)'")
                            self.parent.selectedText = cleanText
                            self.parent.showFlashcardGenerator = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TextSelectionTestView()
}

