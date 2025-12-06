//
//  EmailVerificationView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isEmailVerified = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    // Email verification icon
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Verify Your Email")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("We've sent a verification link to your email address. Please check your inbox and click the link to verify your account.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 30)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.horizontal, 30)
                    }
                    
                    if isEmailVerified {
                        VStack(spacing: 15) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("Email Verified!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("Your email has been successfully verified. You can now access all features of the app.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }
                }
                
                VStack(spacing: 15) {
                    // Resend verification email button
                    Button(action: {
                        Task {
                            await resendVerificationEmail()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Resend Verification Email")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .disabled(isLoading)
                    
                    // Check verification status button
                    Button(action: {
                        Task {
                            await checkVerificationStatus()
                        }
                    }) {
                        Text("Check Verification Status")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .disabled(isLoading)
                    
                    // Sign out button
                    Button(action: {
                        try? firebaseManager.signOut()
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .onAppear {
            checkInitialVerificationStatus()
        }
    }
    
    private func checkInitialVerificationStatus() {
        isEmailVerified = firebaseManager.isEmailVerified()
    }
    
    private func resendVerificationEmail() async {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        do {
            try await firebaseManager.sendEmailVerification()
            await MainActor.run {
                successMessage = "Verification email sent! Please check your inbox."
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func checkVerificationStatus() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await firebaseManager.reloadUser()
            await MainActor.run {
                isEmailVerified = firebaseManager.isEmailVerified()
                if isEmailVerified {
                    successMessage = "Email verified successfully!"
                    // Update authentication status
                    firebaseManager.isAuthenticated = true
                } else {
                    errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(FirebaseManager.shared)
}
