//
//  ContentView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if firebaseManager.isAuthenticated {
                    // Check if email is verified
                    if firebaseManager.isEmailVerified() {
                        VStack(spacing: 0) {
                            // Unified header for all screens
                            VStack(spacing: 8) {
                                Text("Erudit AI")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.4, blue: 0.9),
                                                Color(red: 0.6, green: 0.3, blue: 0.8),
                                                Color(red: 0.9, green: 0.5, blue: 0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Your learning journey starts here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGroupedBackground))
                            
                            // Main app content with native TabView
                            TabView {
                                DashboardView()
                                    .tabItem {
                                        Image(systemName: "house.fill")
                                        Text("Dashboard")
                                    }
                                
                                ReaderView()
                                    .tabItem {
                                        Image(systemName: "book.fill")
                                        Text("Reader")
                                    }
                                
                                FlashcardsView()
                                    .tabItem {
                                        Image(systemName: "rectangle.stack.fill")
                                        Text("Flashcards")
                                    }
                                
                                AccountView()
                                    .tabItem {
                                        Image(systemName: "person.fill")
                                        Text("Account")
                                    }
                            }
                            .accentColor(.blue)
                        }
                    } else {
                        // Show email verification screen
                        EmailVerificationView()
                    }
                } else {
                    AuthView()
                }
            }
        }
        .onAppear {
            // Check authentication status
            if let currentUser = Auth.auth().currentUser {
                firebaseManager.isAuthenticated = true
                firebaseManager.currentUser = currentUser
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseManager.shared)
}
