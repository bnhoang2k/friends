//
//  SignInView.swift
//  friends
//
//  Created by Bryan Hoang on 6/5/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices // Apple Sign In

struct SignInView: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @EnvironmentObject private var avm: AuthenticationVM
    
    @Binding var showSignInView: Bool
    
    private var isValid: Bool {
        !avm.email.isEmpty
        && !avm.pwd.isEmpty
        && Utilities.shared.is_valid_email(email: avm.email)
    }
    
    var body: some View {
        VStack {
            Spacer()
            logo
                .frame(alignment: .centerLastTextBaseline)
            login_email
            login_button
            Spacer()
            googleButton
            appleButton
            su_email
            // TODO: Add a "Forgot Password?" View to send a password reset.
        }
        .frame(width: 300)
        .id(colorScheme)
        .onAppear {avm.resetFields()}
        
    }
}
extension SignInView {
    private var logo: some View {
        Group {
            Text("friends")
                .font(.custom(GlobalVariables.shared.APP_FONT, size: 45))
        }
    }
    private var login_email: some View {
        Group {
            CustomTF(filler_text: "Email", text_binding: $avm.email)
            CustomPF(filler_text: "Password", text_binding: $avm.pwd)
        }
    }
    private var login_button: some View {
        Button {
            Task {
                do {
                    try await avm.signIn()
                    try await avm.handlePostSignIn()
                } catch {
                    print("Login Button: \(error)")
                }
            }
        } label: {
            Text("Login")
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(isValid ? Color.blue : Color.gray.opacity(0.2)))
                .foregroundColor(isValid ? Color.white : Color(UIColor.systemGray))
                .font(.custom(GlobalVariables.shared.APP_FONT, size: 20))
        }
        .disabled(!isValid)
    }
    private var googleButton: some View {
        GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
            Task {
                do {
                    try await avm.signInGoogle()
                    try await avm.handlePostSignIn()
                } catch {
                    print("GoogleSignInButton: \(error)")
                }
            }
        }
        .frame(height: 44)
    }
    // https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
    private var appleButton: some View {
        Button {
            Task {
                do {
                    try await avm.signInApple()
                    try await avm.handlePostSignIn()
                } catch {
                    print("AppleSignInButton: \(error)")
                }
            }
        } label: {
            SignInWithAppleButtonViewRepresentable(type: .default,
                                                   style: colorScheme == .dark ? .white : .black)
            .frame(height: 44)
        }
    }
    private var su_email: some View {
        NavigationLink {
            SignUpView()
                .environmentObject(avm)
                .navigationTitle("Sign Up")
        } label: {
            Text("Don't have an account? Sign up with email")
                .frame(height: 25)
                .font(.footnote)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignInView: .constant(true))
            .environmentObject(AuthenticationVM())
    }
}
