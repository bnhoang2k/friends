//
//  SettingsView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @State private var newValue: String = "" // Placeholder for changing values of fields
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                Section(header: HeaderView(headerText: "User Information")) {
                    updateUsername
                    updateFName
                }
                if avm.authProviders.contains(.email) {
                    Section(header: HeaderView(headerText: "Security")) {
                        updateEmail
                        updatePassword
                    }
                }
                DummyListSections()
                deleteAccountButton
            }
        }
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                try await avm.loadCurrentUser()
            } catch {
                print("Error refreshing user information.")
            }
        }
        .onAppear {
            newValue = ""
        }
    }
}

// MARK: Non. Auth provider dependent.
extension SettingsView {
    private var updateUsername: some View {
        NavigationLink {
            oneField(fieldName: "Username",
                     oldValue: avm.user?.username ?? "Username Error",
                     newValue: $newValue) {
                try await avm.updateUsername(newUsername: newValue)
            }
        } label: {
            HStack {
                LabeledContent("Username", value: avm.user?.username ?? "Username Error")
                Spacer()
            }
            .padding([.leading])
        }
    }
    private var updateFName: some View {
        NavigationLink {
            oneField(fieldName: "Name",
                     oldValue: avm.user?.fullName ?? "Full Name Error",
                     newValue: $newValue) {
                try await avm.updateFName(newFN: newValue)
            }
        } label: {
            HStack {
                LabeledContent("Full Name", value: avm.user?.fullName ?? "Full Name Error")
                Spacer()
            }
            .padding([.leading])
        }
    }
}

// MARK: Email only.
extension SettingsView {
    private var updateEmail: some View {
        NavigationLink {
            updateEmailView(oldValue: avm.user?.email ?? "Email Error",
                            newValue: $newValue) { pwd in
                try await avm.updateEmail(newEmail: newValue, pwd: pwd)
            }
        } label: {
            HStack {
                Label("Update Email", systemImage: "envelope")
                    .foregroundColor(.black)
                Spacer()
            }
            .padding([.leading])
        }
    }
    private var updatePassword: some View {
        NavigationLink {
            updatePasswordView(newValue: $newValue) { email, pwd in
                try await avm.updatePassword(email: email, pwd: pwd, pwdN: newValue)
            }
        } label: {
            HStack {
                Label("Update Password", systemImage: "lock")
                    .foregroundColor(.black)
                Spacer()
            }
            .padding([.leading])
        }
    }
    private var deleteAccountButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try await avm.deleteUser()
                    avm.showSignInView = true
                } catch {
                    print("Delete Account Failed.")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Delete Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                Spacer()
            }
            .padding()
        }
        .buttonStyle(.borderless)
    }
}

extension SettingsView {
    struct oneField: View {
        
        var fieldName: String = ""
        var oldValue: String = ""
        @Binding var newValue: String
        var onButtonTap: (() async throws -> Void)
        
        @Environment(\.dismiss) private var dismiss
        @State private var showAlert: Bool = false
        
        var body: some View {
            VStack {
                CustomTF(filler_text: oldValue, text_binding: $newValue)
                    .onAppear {
                        $newValue.wrappedValue = oldValue
                    }
                    .padding([.top, .bottom, .leading], 7.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .padding([.bottom])
                Button {
                    Task {
                        try await onButtonTap()
                        showAlert.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("OK")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("\(fieldName) updated successfully."), dismissButton: .default(Text("OK")){dismiss()})
            }
            .navigationTitle("Change \(fieldName)")
        }
    }
    struct updateEmailView: View {
        
        var oldValue: String = ""
        @Binding var newValue: String
        @State var pwd: String = ""
        var onButtonTap: ((_ pwd: String) async throws -> Void)
        
        @Environment(\.dismiss) private var dismiss
        @State private var showAlert: Bool = false
        
        var body: some View {
            VStack {
                CustomTF(filler_text: oldValue, text_binding: $newValue)
                    .onAppear {
                        $newValue.wrappedValue = oldValue
                    }
                    .padding([.top, .bottom, .leading], 7.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .padding([.bottom])
                CustomPF(filler_text: "New Password", text_binding: $pwd)
                Button {
                    Task {
                        try await onButtonTap(pwd)
                        showAlert.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("OK")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("An email was sent to verify the email change."), dismissButton: .default(Text("OK")){dismiss()})
            }
            .navigationTitle("Change Email")
        }
    }
    struct updatePasswordView: View {
        
        @State var email: String = ""
        @State var pwd: String = ""
        @Binding var newValue: String
        @State var newValue2: String = ""
        var onButtonTap: ((_ email: String, _ pwd: String) async throws -> Void)
        
        @Environment(\.dismiss) private var dismiss
        @State private var showAlert: Bool = false
        
        private var isValid: Bool {
            !email.isEmpty &&
            !newValue.isEmpty &&
            !newValue2.isEmpty &&
            newValue == newValue2
        }
        
        var body: some View {
            VStack {
                CustomTF(filler_text: "Enter your email", text_binding: $email)
                CustomPF(filler_text: "Enter your old password.", text_binding: $pwd)
                CustomPF(filler_text: "Enter your new password.", text_binding: $newValue)
                CustomPF(filler_text: "Enter your new password again.", text_binding: $newValue2)
                Button {
                    Task {
                        try await onButtonTap(email, pwd)
                        showAlert.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("OK")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                Spacer()
            }
            .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Password changed successfully."), dismissButton: .default(Text("OK")){dismiss()})
            }
            .navigationTitle("Change Password")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AuthenticationVM())
        }
    }
}
