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
    
    @EnvironmentObject var avm: AuthenticationVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var lastDismissAction: DismissAction = .placeholder
    @State private var showImageOptions: Bool = false
    @State private var showCamera: Bool = false
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var tempUIImage: UIImage? = nil
    @State private var selectedUIImage: UIImage? = nil
    
    @State private var showImageCropper: Bool = false
    
    @State private var dummyUser: DBUser? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                    EditPhotoView(dummyUser: $dummyUser, selectedUIImage: $selectedUIImage, showImageOptions: $showImageOptions)
                        .environmentObject(avm)
                    EditUserFieldsView(dummyUser: $dummyUser)
                        .environmentObject(avm)
                    if avm.authProviders.contains(.email) {
                        EditEmailFieldsView(dummyUser: $dummyUser)
                            .environmentObject(avm)
                    }
                    Section {deleteAccountButton} header: {HeaderView(headerText: "")}
                }
            }
        }
        .onAppear {dummyUser = avm.user}
        .sheet(isPresented: $showImageOptions,
               onDismiss: {
            if tempUIImage != nil && lastDismissAction == .photoLibrary { // Only show the cropper if an image was selected
                showImageCropper.toggle()
            }
            else if lastDismissAction == .camera {
                showCamera.toggle()
            }
            lastDismissAction = .placeholder
        },
               content: {
            ImageOptionsView(selectedPhoto: $selectedPhoto) { action in
                lastDismissAction = action
            }
        })
        .fullScreenCover(isPresented: $showImageCropper, content: {
            if let imageToCrop = tempUIImage {
                SwiftyCropView(imageToCrop: imageToCrop, maskShape: .circle) { newImage in
                    selectedUIImage = newImage
                    tempUIImage = nil
                }
            }
        })
        .fullScreenCover(isPresented: $showCamera, content: {
            AccessCameraView(selectedImage: $selectedUIImage, sourceType: .camera)
                .ignoresSafeArea()
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
        .tint(.primary)
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
                    ImageView(selectedPhoto: selectedUIImage, urlString: dummyUser?.photoURL, pictureWidth: 150)
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
        if let imageData = selectedUIImage?.jpegData(compressionQuality: 0.8) {
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AuthenticationVM())
        }
    }
}

struct EditEmailFieldsView: View {
    
    @EnvironmentObject var avm: AuthenticationVM
    @Binding var dummyUser: DBUser?
    
    var body: some View {
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
}

struct EditUserFieldsView: View {
    
    @EnvironmentObject var avm: AuthenticationVM
    @Binding var dummyUser: DBUser?
    
    var body: some View {
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
    }
}
