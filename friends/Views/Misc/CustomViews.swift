//
//  CustomViews.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import SwiftUI
import SwiftyCrop

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

struct changeEmailView: View {
    
    @Binding var newEmail: String
    @Binding var pwd: String
    
    private var isValid: Bool {
        !newEmail.isEmpty
    }
    
    var body: some View {
        VStack {
            CustomTF(filler_text: "New Email", text_binding: $newEmail)
            CustomPF(filler_text: "Password", text_binding: $pwd)
            okButton
        }
        .padding()
    }
    
    private var okButton: some View {
        Button {
            
        } label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(isValid ? Color.blue : Color.gray.opacity(0.2)))
                .foregroundColor(isValid ? Color.white : Color(UIColor.systemGray))
                .fontWeight(.bold)
        }
        .disabled(!isValid)
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

class ImageViewModel: ObservableObject {
    @Published var image: UIImage?
    
    private var imageCache: NSCache<NSString, UIImage>?
    
    init(uiImage: UIImage?, urlString: String?) {
        imageCache = NSCache<NSString, UIImage>()
        if let uiImage = uiImage {
            self.image = uiImage
        } else {
            loadImage(urlString: urlString)
        }
    }
    
    private func loadImage(urlString: String?) {
        guard let urlString = urlString else { return }
        
        if let imageFromCache = getImageFromCache(from: urlString) {
            self.image = imageFromCache
            return
        }
        
        loadImageFromURL(urlString: urlString)
    }
    
    private func loadImageFromURL(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print(error ?? "unknown error")
                return
            }
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let loadedImage = UIImage(data: data) else { return }
                self?.image = loadedImage
                self?.setImageCache(image: loadedImage, key: urlString)
            }
        }.resume()
    }
    
    private func setImageCache(image: UIImage, key: String) {
        imageCache?.setObject(image, forKey: key as NSString)
    }
    
    private func getImageFromCache(from key: String) -> UIImage? {
        return imageCache?.object(forKey: key as NSString)
    }
}


struct ImageView: View {
    @ObservedObject private var imageViewModel: ImageViewModel
    var pictureWidth: CGFloat = 50
    var uiImage: UIImage?

    init(uiImage: UIImage? = nil, urlString: String? = nil, pictureWidth: CGFloat = 50) {
        self.uiImage = uiImage
        self.pictureWidth = pictureWidth
        imageViewModel = ImageViewModel(uiImage: uiImage, urlString: urlString)
    }
    
    var body: some View {
        Image(uiImage: uiImage ?? imageViewModel.image ?? Utilities.shared.generateTestUIImage())
            .resizable()
            .scaledToFit()
            .frame(width: pictureWidth)
            .clipShape(Circle())
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
        //                CustomTF(filler_text: "Test", text_binding: $d1)
        //        CustomPF(filler_text: "test", text_binding: $preview_text)
        //        changeEmailView(newEmail: $d1, pwd: $d2)
        HeaderView(headerText: "xd")
        //        DummyListWrapped()
//                ImageView(urlString: "https://pbs.twimg.com/profile_images/1752515582665068544/3UsnVSp5_400x400.jpg")
//        NavigationStack {
//            testSwiftyCropView()
//        }
    }
}
