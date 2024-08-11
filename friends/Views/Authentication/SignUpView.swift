//
//  SignUpView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct SignUpView: View {
    
    @Environment(\.colorScheme) var color_scheme: ColorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var avm: AuthenticationVM
    
    @State private var pwd2: String = ""
    @State private var showAlert: Bool = false
    
    // TODO: If more fields are added, adjust here.
    private var form_valid: Bool {
        Utilities.shared.is_valid_email(email: avm.email) &&
        Utilities.shared.is_valid_password(password: avm.pwd) &&
        avm.pwd == pwd2
    }
    
    var body: some View {
        VStack {
            // TODO: Add more fields possibly like: username, name, etc.
            CustomTF(filler_text: "Email", text_binding: $avm.email)
            CustomPF(filler_text: "Password", text_binding: $avm.pwd)
            CustomPF(filler_text: "Re-enter password", text_binding: $pwd2)
            signup_button
            Spacer()
        }
        .padding([.top])
        .frame(width: 250)
        .id(color_scheme)
        .onAppear { avm.resetFields() }
    }
}

extension SignUpView {
    private var signup_button: some View {
        Button {
            Task {
                do {
                    try await avm.signUp()
                } catch {
                    print("SignUpView: Error signing up. \(error)")
                }
                showAlert.toggle()
            }
        } label: {
            Text("Sign Up")
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(form_valid ? Color.blue : Color.gray.opacity(0.2)))
                .foregroundColor(form_valid ? Color.white : Color(UIColor.systemGray))
                .font(.custom(GlobalVariables.shared.APP_FONT, size: 20))
        }
        .disabled(!form_valid)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("A verification link has been sent to your email."), dismissButton: .default(Text("OK")){dismiss()})
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthenticationVM())
    }
}
