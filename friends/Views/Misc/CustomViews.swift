//
//  CustomViews.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import SwiftUI
import SwiftyCrop
import Kingfisher

struct CustomTF: View {
    var filler_text: String = ""
    var size: CGFloat = GlobalVariables.shared.textMed
    @Binding var text_binding: String
    
    var body: some View {
        TextField(filler_text, text: $text_binding)
            .font(.custom(GlobalVariables.shared.APP_FONT,
                          size: size))
            .textInputAutocapitalization(.never)
            .truncationMode(.tail)
            .autocorrectionDisabled(true)
            .frame(height: GlobalVariables.shared.TEXTFIELD_FRAMEHEIGHT)
    }
}

struct CustomPF: View {
    @State private var show_password: Bool = false
    var filler_text: String = ""
    var size: CGFloat = GlobalVariables.shared.textMed
    var eye: Bool = true
    @Binding var text_binding: String
    
    var body: some View {
        HStack {
            Group {
                if show_password {TextField(filler_text, text: $text_binding)}
                else {SecureField(filler_text, text: $text_binding)}
            }
            .font(.custom(GlobalVariables.shared.APP_FONT,
                          size: size))
            .textInputAutocapitalization(.never)
            .truncationMode(.tail)
            .autocorrectionDisabled(true)
            .frame(height: 30, alignment: .leading)
            if (eye) {
                Button {
                    show_password.toggle()
                } label: {
                    Image(systemName: show_password ? "eye.slash" : "eye")
                        .foregroundColor(Color.primary)
                        .opacity(0.6)
                }
                .frame(alignment: .trailing)
            }
        }
        .frame(height: GlobalVariables.shared.TEXTFIELD_FRAMEHEIGHT)
    }
}

struct ConditionalButton: View {
    var isDisabled: Bool
    var buttonText: String
    var buttonAction: () -> Void

    var body: some View {
        Button(action: buttonAction) {
            Text(buttonText)
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(isDisabled ? Color.gray.opacity(0.2) : Color.blue))
                .foregroundColor(isDisabled ? Color(UIColor.systemGray) : .white)
                .font(.custom(GlobalVariables.shared.APP_FONT,
                              size: GlobalVariables.shared.textMed))
        }
        .disabled(isDisabled)
    }
}

struct HeaderView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @State var headerText: String = ""
    
    var body: some View {
        Text(headerText)
            .font(.custom(GlobalVariables.shared.APP_FONT,
                          size: GlobalVariables.shared.textMed))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .zIndex(1) // Ensure the header stays above the scrolling content
    }
}

struct ImageView: View {
    
    var selectedPhoto: UIImage? = nil
    var urlString: String?
    var pictureWidth: CGFloat
    
    init(selectedPhoto: UIImage? = nil, urlString: String? = nil, pictureWidth: CGFloat = 50) {
        self.selectedPhoto = selectedPhoto
        self.urlString = urlString
        self.pictureWidth = pictureWidth
    }
    
    var body: some View {
        Group {
            if let photo = selectedPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pictureWidth)
                    .clipShape(Circle())
            }
            else if let urlString = urlString, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFit()
                    .frame(width: pictureWidth)
                    .clipShape(Circle())
            } else {
                KFImage(URL(string: "https://pbs.twimg.com/profile_images/1752515582665068544/3UsnVSp5_400x400.jpg"))
                    .placeholder {
                        ProgressView()
                    }
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFit()
                    .frame(width: pictureWidth)
                    .clipShape(Circle())
            }
        }
    }
}

struct testSwiftyCropView: View {
    @State private var showSheet: Bool = false
    var body: some View {
        ScrollView {
            LazyVStack {
                ZStack {
                    Button("Open sheet") {
                        showSheet.toggle()
                    }
                }
                .padding(.top)
            }
        }
        .fullScreenCover(isPresented: $showSheet, content: {
            SwiftyCropView(imageToCrop: Utilities.shared.generateTestUIImage(), maskShape: .circle) { person in
                print("xd")
            }
        })
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserCard: View {
    var user: DBUser  // Proper declaration
    var showfullName: Bool? = true
    var showUsername: Bool? = true
    
    var body: some View {
        HStack {
            ImageView(urlString: user.photoURL, pictureWidth: 40)
            VStack(alignment: .leading) {
                Text(user.fullName ?? "Unknown Name")
                    .font(.custom(GlobalVariables.shared.APP_FONT,
                                  size: GlobalVariables.shared.textMed))
                Text(user.username ?? "@unknown")
                    .font(.custom(GlobalVariables.shared.APP_FONT,
                                  size: GlobalVariables.shared.textBody))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SearchBar: View {
    var placeholderText: String
    @Binding var searchText: String
    var body: some View {
        TextField(placeholderText, text: $searchText)
            .multilineTextAlignment(.center)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                }
            )
            .font(.custom(GlobalVariables.shared.APP_FONT,
                          size: GlobalVariables.shared.textBody))
    }
}

struct CustomViews_Previews: PreviewProvider {
    static var previews: some View {
        @State var d1: String = ""
        @State var d2: String = ""
        ImageView(urlString: "https://pbs.twimg.com/profile_images/1752515582665068544/3UsnVSp5_400x400.jpg", pictureWidth: 50)
    }
}
