//
//  EPUBPaginationReaderView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import WebKit

/// EPUB Reader View with proper pagination - displays text page by page like Apple Books
struct EPUBPaginationReaderView: View {
    let book: Book
    @State private var fullText: String = ""
    @State private var pages: [EPUBPaginationService.Page] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var pageSize: CGSize = .zero
    @State private var currentPage: Int = 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading EPUB...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    // Error state
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
                } else if pages.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Content")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This EPUB file appears to be empty")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Reader content with proper pagination
                    VStack(spacing: 0) {
                        // WebView with separate pages
                        EPUBPageWebView(
                            pages: pages,
                            pageSize: pageSize,
                            currentPage: $currentPage
                        )
                        .frame(width: pageSize.width, height: pageSize.height)
                        .id("\(pageSize.width)x\(pageSize.height)-\(pages.count)") // Force reload when size or pages change
                        
                        // Navigation buttons
                        NavigationButtonsView(
                            currentPage: currentPage,
                            totalPages: pages.count,
                            canGoBack: currentPage > 1,
                            canGoForward: currentPage < pages.count,
                            onPrevious: {
                                if currentPage > 1 {
                                    currentPage -= 1
                                }
                            },
                            onNext: {
                                if currentPage < pages.count {
                                    currentPage += 1
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                }
            }
            .onAppear {
                // Set page size based on geometry
                updatePageSize(from: geometry.size)
                
                // Load EPUB content
                loadEPUB()
            }
            .onChange(of: geometry.size) { newSize in
                // Update page size when geometry changes
                updatePageSize(from: newSize)
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Update page size from geometry
    private func updatePageSize(from size: CGSize) {
        let navigationButtonHeight: CGFloat = 80
        let newPageSize = CGSize(
            width: size.width,
            height: max(100, size.height - navigationButtonHeight)
        )
        
        if abs(newPageSize.width - pageSize.width) > 1 || abs(newPageSize.height - pageSize.height) > 1 {
            pageSize = newPageSize
            // Repaginate when size changes
            if !fullText.isEmpty {
                repaginate()
            }
        }
    }
    
    /// Load EPUB content
    private func loadEPUB() {
        guard let filePath = book.filePath else {
            errorMessage = "File path is missing"
            isLoading = false
            return
        }
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            errorMessage = "EPUB file not found"
            isLoading = false
            return
        }
        
        guard pageSize.width > 0 && pageSize.height > 0 else {
            // Wait for page size to be set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadEPUB()
            }
            return
        }
        
        Task {
            do {
                // Parse EPUB and extract text
                let text = try await EPUBService.parseEPUB(filePath: filePath)
                
                await MainActor.run {
                    self.fullText = text
                    self.repaginate()
                    self.isLoading = false
                    print("📚 EPUB loaded: \(text.count) characters, \(pages.count) pages")
                }
            } catch {
                await MainActor.run {
                    if let epubError = error as? EPUBError {
                        self.errorMessage = epubError.errorDescription
                    } else {
                        self.errorMessage = "Failed to load EPUB: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Repaginate text into pages
    private func repaginate() {
        guard !fullText.isEmpty && pageSize.width > 0 && pageSize.height > 0 else {
            return
        }
        
        let paginatedPages = EPUBPaginationService.paginate(
            text: fullText,
            config: .default,
            pageSize: pageSize
        )
        
        pages = paginatedPages
        currentPage = min(currentPage, max(1, pages.count))
        
        print("📄 Repaginated: \(pages.count) pages")
    }
}

// MARK: - EPUB Page WebView
struct EPUBPageWebView: UIViewRepresentable {
    let pages: [EPUBPaginationService.Page]
    let pageSize: CGSize
    @Binding var currentPage: Int
    
    /// Create HTML content with separate pages
    private func createHTMLContent() -> String {
        guard !pages.isEmpty else {
            return "<html><body></body></html>"
        }
        
        // Create HTML for each page
        let pageDivs = pages.enumerated().map { index, page in
            let escapedText = page.content
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
            
            // Convert newlines to paragraphs
            let paragraphs = escapedText.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { "<p>\($0)</p>" }
                .joined(separator: "")
            
            return """
            <div class="page" data-page="\(index + 1)">
                <div class="page-content">
                    \(paragraphs)
                </div>
            </div>
            """
        }.joined(separator: "\n")
        
        let pageWidth = Int(pageSize.width)
        let pageHeight = Int(pageSize.height)
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                html, body {
                    width: 100%;
                    height: 100%;
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                }
                
                #container {
                    display: flex;
                    width: \(pageWidth * pages.count)px;
                    height: 100%;
                    overflow-x: auto;
                    overflow-y: hidden;
                    scroll-snap-type: x mandatory;
                    -webkit-overflow-scrolling: touch;
                }
                
                .page {
                    width: \(pageWidth)px;
                    height: 100%;
                    flex-shrink: 0;
                    scroll-snap-align: start;
                    scroll-snap-stop: always;
                    overflow: hidden;
                    position: relative;
                }
                
                .page-content {
                    width: 100%;
                    height: 100%;
                    padding: 40px 20px;
                    overflow: hidden;
                    
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
                    font-size: 18px;
                    line-height: 1.6;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    
                    color: #000000;
                    background-color: #ffffff;
                }
                
                p {
                    margin-bottom: 1em;
                    text-align: justify;
                }
            </style>
        </head>
        <body>
            <div id="container">
                \(pageDivs)
            </div>
        </body>
        </html>
        """
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Configure scroll view for horizontal pagination
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.isPagingEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.scrollView.decelerationRate = .fast
        webView.scrollView.isDirectionalLockEnabled = true
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.scrollView.clipsToBounds = true
        webView.clipsToBounds = true
        
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Add JavaScript to handle page navigation
        let script = """
        (function() {
            const container = document.getElementById('container');
            if (!container) return;
            
            function scrollToPage(page) {
                const pageWidth = \(Int(pageSize.width));
                const scrollX = (page - 1) * pageWidth;
                container.scrollTo({
                    left: scrollX,
                    behavior: 'auto'
                });
            }
            
            // Expose scrollToPage function
            window.scrollToPage = scrollToPage;
            
            // Snap to page on scroll end
            let scrollTimeout;
            container.addEventListener('scroll', function() {
                clearTimeout(scrollTimeout);
                scrollTimeout = setTimeout(function() {
                    const pageWidth = \(Int(pageSize.width));
                    const scrollLeft = container.scrollLeft;
                    const currentPage = Math.round(scrollLeft / pageWidth) + 1;
                    const targetScroll = (currentPage - 1) * pageWidth;
                    container.scrollLeft = targetScroll;
                }, 100);
            });
        })();
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Load HTML content
        let htmlContent = createHTMLContent()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload if pages or size changed
        let contentKey = "\(pages.count)-\(pageSize.width)-\(pageSize.height)"
        if contentKey != context.coordinator.lastContentKey {
            context.coordinator.lastContentKey = contentKey
            let htmlContent = createHTMLContent()
            webView.loadHTMLString(htmlContent, baseURL: nil)
            context.coordinator.lastPage = 0
        }
        
        // Scroll to current page if needed
        if currentPage != context.coordinator.lastPage && currentPage > 0 && currentPage <= pages.count {
            context.coordinator.lastPage = currentPage
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                webView.evaluateJavaScript("window.scrollToPage(\(currentPage));", completionHandler: nil)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var lastContentKey: String = ""
        var lastPage: Int = 0
    }
}

// MARK: - Navigation Buttons View
struct NavigationButtonsView: View {
    let currentPage: Int
    let totalPages: Int
    let canGoBack: Bool
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            // Previous button
            Button(action: onPrevious) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(canGoBack ? .white : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(canGoBack ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
            }
            .disabled(!canGoBack)
            
            Spacer()
            
            // Page indicator
            Text("\(currentPage) / \(totalPages)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Next button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(canGoForward ? .white : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(canGoForward ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
            }
            .disabled(!canGoForward)
        }
    }
}

#Preview {
    NavigationView {
        EPUBPaginationReaderView(
            book: Book(
                id: "test",
                title: "Test EPUB",
                author: "Test Author",
                coverUrl: "",
                openedAt: Date(),
                filePath: nil,
                fileType: "epub",
                lastReadPage: 0
            )
        )
    }
}
