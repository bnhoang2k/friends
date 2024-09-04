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
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                ZStack {
                    HStack {
                        Spacer()
                        ImageView(urlString: avm.user?.photoURL, pictureWidth: 150)
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
                .padding(.top)
                deleteAccountButton
            }
        }
        .task {
            do {try await avm.loadCurrentUser()}
            catch {print("Error refreshing user information.")}
        }
        .sheet(isPresented: $showImageOptions, onDismiss: {
            if selectedUIImage != nil {
                showImageCropper.toggle()
            }
        }, content: {
            ImageOptionsView(selectedPhoto: $selectedPhoto,
                             selectedUIImage: $selectedUIImage,
                             showImageCropper: $showImageCropper)
        })
        .fullScreenCover(isPresented: $showImageCropper, content: {
            SwiftyCropView(imageToCrop: selectedUIImage ?? Utilities.shared.generateTestUIImage(), maskShape: .circle) { newImage in
                
            }
        })
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto {
                Task {
                    if let image = await loadImage(from: newPhoto) {
                        selectedUIImage = image
                        selectedPhoto = nil
                    }
                }
            }
        }
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ImageOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedUIImage: UIImage?
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
                dismiss()
            }
            .padding(.top)
        }
        .padding(.horizontal)
        .presentationDetents([.fraction(0.15)])
    }
}

// MARK: Misc.
extension SettingsView {
    
    func loadImage(from photo: PhotosPickerItem) async -> UIImage? {
        if let data = try? await photo.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            return image
        }
        return nil
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
            .padding(.all)
        }
        .buttonStyle(.borderless)
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
