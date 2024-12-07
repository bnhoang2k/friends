//  SignInView.swift
//  friends
//
//  Created by Bryan Hoang on 6/5/24.

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices // Apple Sign In

struct SignInView: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @EnvironmentObject private var avm: AuthenticationVM
    
    @Binding var showSignInView: Bool
    
    // Validation logic extracted for readability and separation of concerns
    private var disableButton: Bool {
        avm.email.isEmpty ||
        avm.pwd.isEmpty ||
        !Utilities.shared.is_valid_email(email: avm.email)
    }
    
    var body: some View {
        VStack {
            Spacer()
            logo
                .frame(alignment: .centerLastTextBaseline)
            loginForm
            loginButton
            Spacer()
            socialSignInButtons
            emailSignUpLink
        }
        .frame(width: 300)
        .onAppear { avm.resetFields() }
    }
}

// MARK: - Subviews
extension SignInView {
    
    // App logo at the top
    private var logo: some View {
        Text("friends")
            .font(.custom(GlobalVariables.shared.APP_FONT, size: 45))
    }
    
    // Grouped email and password fields
    private var loginForm: some View {
        Group {
            CustomTF(filler_text: "Email", text_binding: $avm.email)
            CustomPF(filler_text: "Password", text_binding: $avm.pwd)
        }
    }
    
    // Login button with validation
    private var loginButton: some View {
        ConditionalButton(isDisabled: disableButton,
                          buttonText: "Login") {
            handleLogin()
        }
    }
    
    // Social sign-in buttons grouped for cleaner layout
    private var socialSignInButtons: some View {
        VStack(spacing: 10) {
            googleButton
            appleButton
        }
    }
    
    // Google sign-in button
    private var googleButton: some View {
        GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
            handleGoogleSignIn()
        }
        .frame(height: 44)
    }
    
    // Apple sign-in button
    private var appleButton: some View {
        Button(action: handleAppleSignIn) {
            SignInWithAppleButtonViewRepresentable(type: .default, style: colorScheme == .dark ? .white : .black)
                .frame(height: 44)
        }
    }
    
    // Sign-up link
    private var emailSignUpLink: some View {
        NavigationLink(destination: SignUpView()
                        .environmentObject(avm)
                        .navigationTitle("Sign Up")) {
            Text("Don't have an account? Sign up with email")
                .frame(height: 25)
                .font(.footnote)
        }
    }
}

// MARK: - Actions
extension SignInView {
    
    private func handleLogin() {
        Task {
            do {
                try await avm.signIn()
                try await avm.handlePostSignIn()
            } catch {
                print("Login Error: \(error)")
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                try await avm.signInGoogle()
                try await avm.handlePostSignIn()
            } catch {
                print("Google Sign-In Error: \(error)")
            }
        }
    }
    
    private func handleAppleSignIn() {
        Task {
            do {
                try await avm.signInApple()
                try await avm.handlePostSignIn()
            } catch {
                print("Apple Sign-In Error: \(error)")
            }
        }
    }
}

// MARK: - Preview
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true))
            .environmentObject(AuthenticationVM())
    }
}
