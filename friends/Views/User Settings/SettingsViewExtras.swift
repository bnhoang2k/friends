//
//  SettingsViewExtras.swift
//  friends
//
//  Created by Bryan Hoang on 9/5/24.
//

import SwiftUI
import PhotosUI

extension SettingsView {
    
    enum DismissAction {
        case camera
        case photoLibrary
        case placeholder
    }
    
    struct ImageOptionsView: View {
        
        @Environment(\.dismiss) private var dismiss
        @Binding var selectedPhoto: PhotosPickerItem?
        
        var onDismissAction: ((DismissAction) -> Void)?
        
        var body: some View {
            VStack {
                Button {
                    onDismissAction?(.camera)
                    dismiss()
                } label: {
                    HStack {
                        Label("Take a photo", systemImage: "camera")
                        Spacer()
                    }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Pick from library", systemImage: "photo")
                    Spacer()
                }
                .onChange(of: selectedPhoto) { newPhoto in
                    onDismissAction?(.photoLibrary)
                    dismiss()  // Dismiss after picking a photo
                }
                .padding(.top)
            }
            .padding(.horizontal)
            .presentationDetents([.fraction(0.15)])
        }
    }
    
    var deleteAccountButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try await avm.deleteUser()
                    avm.showSignInView = true
                } catch {
                    print("Error deleting user: \(error)")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Delete Account")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                Spacer()
            }
        }
        .buttonStyle(.borderless)
    }
}

// MARK: Non - email fields
struct EditFieldView<T>: View {
    @Binding var value: T?
    var fieldName: String
    var imageName: String
    
    var body: some View {
        HStack {
            Label(fieldName, systemImage: imageName)
            Spacer()
            if T.self == String.self {
                TextField("Enter \(fieldName)", text: Binding(
                    get: { value as? String ?? "" },
                    set: { newValue in
                        value = newValue as? T
                    })
                )
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.trailing)
            }
            // extend this to support other types like Int, Double, etc.
        }
        .padding(.horizontal)
    }
}

struct EditPasswordView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    
    @State private var email: String = ""
    @State private var pwd: String = ""
    @State private var nPwd: String = ""
    @State private var nPwd2: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert: Bool = false
    
    // TODO: If more fields are added, adjust here.
    private var isValid: Bool {
        Utilities.shared.is_valid_email(email: email) &&
        email == avm.user?.email! &&
        Utilities.shared.is_valid_password(password: nPwd) &&
        nPwd == nPwd2
    }
    
    var body: some View {
        VStack {
            CustomTF(filler_text: "Enter your email", text_binding: $email)
            CustomPF(filler_text: "Enter your old password", eye: true,text_binding: $pwd)
            CustomPF(filler_text: "Enter your new password", eye: true,text_binding: $nPwd)
            CustomPF(filler_text: "Enter your new password again", eye: true,text_binding: $nPwd2)
            okButton
            Spacer()
        }
        .padding()
        .navigationTitle("Edit Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var okButton: some View {
        Button {
            Task {
                do {
                    try await avm.updatePassword(email: email, pwd: pwd, pwdN: nPwd)
                } catch {
                    print("SignUpView: Error signing up. \(error)")
                }
                showAlert.toggle()
            }
        } label: {
            Text("OK")
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(isValid ? Color.blue : Color.gray.opacity(0.2)))
                .foregroundColor(isValid ? Color.white : Color(UIColor.systemGray))
                .font(.custom(GlobalVariables.shared.APP_FONT, size: 20))
        }
        .disabled(!isValid)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("A verification link has been sent to your email."), dismissButton: .default(Text("OK")){dismiss()})
        }
    }
}
