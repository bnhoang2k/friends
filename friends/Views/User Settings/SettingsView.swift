//
//  SettingsView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI
import PhotosUI
import SwiftyCrop

struct SettingsView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var showImageOptions: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    
    @State private var showImageCropper: Bool = false
    @State private var tempUIImage: UIImage? = nil  // Temporary UIImage for cropping
    
    @State private var dummyUser: DBUser? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                    EditPhotoView(dummyUser: $dummyUser, selectedUIImage: $selectedUIImage, showImageOptions: $showImageOptions)
                        .environmentObject(avm)
                    Section {
                        EditFieldView(
                            value: Binding(
                                get: { dummyUser?.username ?? "" },
                                set: { dummyUser?.username = $0 }
                            ),
                            fieldName: "Username",
                            imageName: "at"
                        )
                        EditFieldView(
                            value: Binding(
                                get: { dummyUser?.fullName ?? "" },
                                set: { dummyUser?.fullName = $0 }
                            ),
                            fieldName: "Full Name",
                            imageName: "person"
                        )
                    } header: {HeaderView(headerText: "User Information")}
                    if avm.authProviders.contains(.email) {
                        Section {
                            EditFieldView(
                                value: Binding(
                                    get: { dummyUser?.email ?? "" },
                                    set: { dummyUser?.email = $0 }
                                ),
                                fieldName: "Email",
                                imageName: "envelope"
                            )
                            HStack {
                                NavigationLink {
                                    EditPasswordView()
                                        .environmentObject(avm)
                                } label: {
                                    HStack {
                                        Label("Password", systemImage: "lock.rectangle")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding(.horizontal)
                                    .foregroundColor(.primary)
                                }
                            }
                        } header: {
                            HeaderView(headerText: "Security")
                        }
                    }
                    Section {
                        deleteAccountButton
                    } header: {
                        HeaderView(headerText: "")
                    }
                }
            }
        }
        .onAppear {
            dummyUser = avm.user
        }
        .sheet(isPresented: $showImageOptions,
               onDismiss: {
            if tempUIImage != nil { // Only show the cropper if an image was selected
                showImageCropper.toggle()
            }
        },
               content: {
            ImageOptionsView(selectedPhoto: $selectedPhoto,
                             tempUIImage: $tempUIImage,  // Use tempUIImage for cropping
                             showImageCropper: $showImageCropper)
        })
        .fullScreenCover(isPresented: $showImageCropper, content: {
            if let imageToCrop = tempUIImage {
                SwiftyCropView(imageToCrop: imageToCrop, maskShape: .circle) { newImage in
                    selectedUIImage = newImage
                    tempUIImage = nil  // Reset tempUIImage after cropping
                }
            }
        })
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto {
                Task {
                    if let image = await loadImage(from: newPhoto) {
                        tempUIImage = image  // Store the selected image temporarily for cropping
                        selectedPhoto = nil
                    }
                }
            }
        }
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        try await saveChanges()
                        dismiss()
                    }
                },label: {
                    Text("Save")
                })
            }
        }
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

private struct ImageOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var tempUIImage: UIImage?  // Temporary UIImage for cropping
    @Binding var showImageCropper: Bool
    
    var body: some View {
        VStack {
            HStack {
                Label("Take a photo", systemImage: "camera")
                Spacer()
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Pick from library", systemImage: "photo")
                Spacer()
            }
            .onChange(of: selectedPhoto) { newPhoto in
                dismiss()  // Dismiss after picking a photo
            }
            .padding(.top)
        }
        .padding(.horizontal)
        .presentationDetents([.fraction(0.15)])
    }
}

// MARK: Misc.
extension SettingsView {
    
    struct EditPhotoView: View {
        
        @EnvironmentObject var avm: AuthenticationVM
        @Binding var dummyUser: DBUser?
        @Binding var selectedUIImage: UIImage?
        @Binding var showImageOptions: Bool
        
        var body: some View {
            ZStack {
                HStack {
                    Spacer()
                    ImageView(uiImage: selectedUIImage, urlString: dummyUser?.photoURL, pictureWidth: 150)
                    Spacer()
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.largeTitle)
                        Spacer()
                    }
                }
            }
            .onTapGesture {showImageOptions.toggle()}
            .padding(.vertical)
        }
    }
    
    func loadImage(from photo: PhotosPickerItem) async -> UIImage? {
        if let data = try? await photo.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    func saveChanges() async throws {
        guard var dummyUser else { return }

        // Check if there is a new profile image to upload
        if let imageData = selectedUIImage?.jpegData(compressionQuality: 0.5) {
            do {
                // 1. Upload the image to Firebase Storage
                let downloadURL = try await UserManager.shared.uploadProfileImage(uid: dummyUser.uid, imageData: imageData)
                
                // 2. Update the profile picture URL in Firebase Authentication
                try await AuthenticationManager.shared.updateProfilePictureURL(downloadURL: downloadURL)
                
                // 3. Update the user object with the new photo URL
                dummyUser.photoURL = downloadURL
            } catch {
                print("Error uploading image: \(error)")
                throw error
            }
        }

        // 4. Update user information in Firestore
        do {
            try await UserManager.shared.updateUser(avm.user!, with: dummyUser)
            try await avm.loadCurrentUser(newUser: dummyUser)
        } catch {
            print("Error updating user information in Firestore: \(error)")
            throw error
        }
    }
    
    private var deleteAccountButton: some View {
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            //            @State var v1: String = "asdf"
            SettingsView()
                .environmentObject(AuthenticationVM())
            //            EditFieldView(value: $v1, fieldName: "bruh", imageName: "at")
            //            EditPasswordView()
            //                .environmentObject(AuthenticationVM())
        }
    }
}
