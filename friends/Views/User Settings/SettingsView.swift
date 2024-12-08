//
//  SettingsView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI
import PhotosUI
import SwiftyCrop

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
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
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
                    Section {
                        deleteAccountButton
                    } header: {
                        HeaderView(headerText: "")
                    }
                }
            }
        }
        .onAppear { dummyUser = avm.user }
        .sheet(isPresented: $showImageOptions, onDismiss: handleImageOptionsDismiss) {
            ImageOptionsView(selectedPhoto: $selectedPhoto) { action in
                lastDismissAction = action
            }
        }
        .fullScreenCover(isPresented: $showImageCropper) {
            if let imageToCrop = tempUIImage {
                SwiftyCropView(imageToCrop: imageToCrop, maskShape: .circle) { newImage in
                    selectedUIImage = newImage
                    tempUIImage = nil
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            AccessCameraView(selectedImage: $selectedUIImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { handleSelectedPhotoChange($0) }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: handleSave)
            }
        }
        .tint(.primary)
    }
}

// MARK: - Subviews
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
                        Image(systemName: "pencil")
                            .font(.largeTitle)
                        Spacer()
                    }
                }
            }
            .onTapGesture { showImageOptions.toggle() }
            .padding(.vertical)
        }
    }
}

// MARK: - Helper Methods
extension SettingsView {
    func handleImageOptionsDismiss() {
        if tempUIImage != nil && lastDismissAction == .photoLibrary {
            showImageCropper.toggle()
        } else if lastDismissAction == .camera {
            showCamera.toggle()
        }
        lastDismissAction = .placeholder
    }
    
    func handleSelectedPhotoChange(_ newPhoto: PhotosPickerItem?) {
        guard let newPhoto else { return }
        Task {
            if let image = await loadImage(from: newPhoto) {
                tempUIImage = image
                selectedPhoto = nil
            }
        }
    }
    
    func handleSave() {
        Task {
            do {
                try await saveChanges()
                dismiss()
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
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

        if let imageData = selectedUIImage?.jpegData(compressionQuality: 0.8) {
            let downloadURL = try await UserManager.shared.uploadProfileImage(uid: dummyUser.uid, imageData: imageData)
            try await AuthenticationManager.shared.updateProfilePictureURL(downloadURL: downloadURL)
            dummyUser.photoURL = downloadURL
        }

        try await UserManager.shared.updateUser(avm.user!, with: dummyUser)
        try await avm.loadCurrentUser(newUser: dummyUser)
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
