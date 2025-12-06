//
//  AuthView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .onAppear {
            if firebaseManager.isAuthenticated {
                // Navigate to main app
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.3, green: 0.2, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Overlay gradient for depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.6).opacity(0.3),
                    Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.8)
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            
            // Accent gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.2),
                    Color.clear,
                    Color(red: 0.2, green: 0.4, blue: 0.7).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 50)
                loginCard
                Spacer(minLength: 50)
            }
            .frame(minHeight: UIScreen.main.bounds.height)
        }
    }
    
    private var loginCard: some View {
        VStack(spacing: 24) {
            appTitle
            inputFields
            rememberMeSection
            errorMessageSection
            loginButton
            socialButtons
            signupLink
        }
        .padding(24)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }
    
    private var appTitle: some View {
        VStack(spacing: 8) {
            Text("Erudit AI")
                .font(.system(size: 32, weight: .bold, design: .rounded))
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    
    private var inputFields: some View {
        VStack(spacing: 16) {
            emailField
            passwordField
        }
    }
    
    private var emailField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField("User Name", text: $email)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.black)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accentColor(.blue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(fieldBackground)
    }
    
    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if showPassword {
                TextField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.black)
                    .accentColor(.blue)
            } else {
                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.black)
                    .accentColor(.blue)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(fieldBackground)
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var rememberMeSection: some View {
        HStack {
            Button(action: {
                // Toggle remember me functionality
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                        )
                    
                    Text("Remember me")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
        }
    }
    
    private var errorMessageSection: some View {
        Group {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var loginButton: some View {
        Button(action: {
            Task {
                await performAuth()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(isSignUp ? "Sign Up" : "Login")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(loginButtonGradient)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .disabled(isLoading || email.isEmpty || password.isEmpty)
    }
    
    private var loginButtonGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.4, blue: 0.9),
                Color(red: 0.6, green: 0.3, blue: 0.8),
                Color(red: 0.9, green: 0.5, blue: 0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var signupLink: some View {
        HStack {
            Text("Don't have an account?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Button(action: {
                isSignUp.toggle()
                errorMessage = ""
            }) {
                Text("Signup")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var socialButtons: some View {
        HStack(spacing: 20) {
            googleButton
            appleButton
        }
    }
    
    private var googleButton: some View {
        Button(action: {
            Task {
                await performGoogleAuth()
            }
        }) {
            Text("G")
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.8))
                )
        }
        .disabled(isLoading)
    }
    
    private var appleButton: some View {
        Button(action: {
            Task {
                await performAppleAuth()
            }
        }) {
            Image(systemName: "applelogo")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.8))
                )
        }
        .disabled(isLoading)
    }
    
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func performAuth() async {
        isLoading = true
        errorMessage = ""
        
        do {
            if isSignUp {
                try await firebaseManager.signUp(email: email, password: password)
                await MainActor.run {
                    errorMessage = ""
                    isLoading = false
                }
            } else {
                try await firebaseManager.signIn(email: email, password: password)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func performGoogleAuth() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await firebaseManager.signInWithGoogle()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func performAppleAuth() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await firebaseManager.signInWithApple()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(FirebaseManager.shared)
}
