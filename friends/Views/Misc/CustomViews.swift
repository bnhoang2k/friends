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
    var size: CGFloat = 20
    @Binding var text_binding: String
    
    var body: some View {
        TextField(filler_text, text: $text_binding)
            .font(.custom(GlobalVariables.shared.APP_FONT, size: size))
            .textInputAutocapitalization(.never)
            .truncationMode(.tail)
            .autocorrectionDisabled(true)
            .frame(height: GlobalVariables.shared.TEXTFIELD_FRAMEHEIGHT)
    }
}

struct CustomPF: View {
    @State private var show_password: Bool = false
    var filler_text: String = ""
    var size: CGFloat = 20
    var eye: Bool = true
    @Binding var text_binding: String
    @Environment(\.colorScheme) var color_scheme: ColorScheme
    
    var body: some View {
        HStack {
            Group {
                if show_password {TextField(filler_text, text: $text_binding)}
                else {SecureField(filler_text, text: $text_binding)}
            }
            .font(.custom(GlobalVariables.shared.APP_FONT, size: size))
            .textInputAutocapitalization(.never)
            .truncationMode(.tail)
            .autocorrectionDisabled(true)
            .frame(height: 30, alignment: .leading)
            if (eye) {
                Button {
                    show_password.toggle()
                } label: {
                    Image(systemName: show_password ? "eye.slash" : "eye")
                        .foregroundColor(color_scheme == .dark ? .white : .black)
                        .opacity(0.6)
                }
                .frame(alignment: .trailing)
            }
        }
        .frame(height: GlobalVariables.shared.TEXTFIELD_FRAMEHEIGHT)
    }
}

struct HeaderView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @State var headerText: String = ""
    
    var body: some View {
        Text(headerText)
            .font(.custom(GlobalVariables.shared.APP_FONT, size: 20, relativeTo: .headline))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .zIndex(1) // Ensure the header stays above the scrolling content
    }
}

struct DummyListSections: View {
    
    var body: some View {
        Section(header: HeaderView(headerText: "Fruits")) {
            ForEach(0..<25) { index in
                HStack {
                    Text("Fruit \(index + 1)")
                }
                .padding([.leading])
            }
        }
        
        Section(header: HeaderView(headerText: "Vegetables")) {
            ForEach(0..<25) { index in
                HStack {
                    Text("Vegetable \(index + 1)")
                }
                .padding([.leading])
            }
        }
        
        Section(header: HeaderView(headerText: "Dairy Products")) {
            ForEach(0..<25) { index in
                HStack {
                    Text("Dairy Product \(index + 1)")
                }
                .padding([.leading])
            }
        }
    }
}

struct DummyListWrapped: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                DummyListSections()
            }
        }
        .navigationTitle("Dummy List")
    }
}

struct ImageView: View {
    
    var selectedPhoto: UIImage? = nil
    var urlString: String?
    var pictureWidth: CGFloat = 50
    private var processor: ResizingImageProcessor? = nil
    
    init(selectedPhoto: UIImage? = nil, urlString: String?, pictureWidth: CGFloat = 50) {
        self.selectedPhoto = selectedPhoto
        self.urlString = urlString
        self.pictureWidth = pictureWidth
        self.processor = ResizingImageProcessor(referenceSize: CGSize(width: pictureWidth,
                                                                      height: pictureWidth),
                                                mode: .aspectFit)
    }
    
    var body: some View {
        if let photo = selectedPhoto {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .frame(width: pictureWidth)
                .clipShape(.circle)
        }
        else if let urlString = urlString, let url = URL(string: urlString) {
            KFImage
                .url(url)
                .placeholder { progress in
                    ProgressView()
                }
                .setProcessor(processor!)
                .loadDiskFileSynchronously()
                .cacheMemoryOnly()
                .lowDataModeSource(.network(url))
                .onProgress { receivedSize, totalSize in}
                .onSuccess { RetrieveImageResult in
                }
                .onFailure { KingfisherError in
                }
                .resizable()
                .scaledToFit()
                .frame(width: pictureWidth)
                .clipShape(.circle)
        }
        else {
            ProgressView()
                .frame(width: pictureWidth,
                       height: pictureWidth)
                .clipShape(.circle)
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

struct CustomViews_Previews: PreviewProvider {
    static var previews: some View {
        @State var d1: String = ""
        @State var d2: String = ""
        ImageView(urlString: "https://pbs.twimg.com/profile_images/1752515582665068544/3UsnVSp5_400x400.jpg", pictureWidth: 50)
    }
}
