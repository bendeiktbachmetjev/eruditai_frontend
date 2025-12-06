//
//  AccountView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // User info
            VStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Account")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let user = firebaseManager.currentUser {
                    Text("Welcome, \(user.displayName ?? user.email ?? "User")")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Text("Your profile and settings will be here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Sign out button
            Button("Sign Out") {
                try? firebaseManager.signOut()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.bottom, 20)
        }
        .padding()
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    AccountView()
        .environmentObject(FirebaseManager.shared)
}
