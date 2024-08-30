//
//  CustomViews.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import SwiftUI

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

struct DummyList: View {
    var body: some View {
        Section(header: Text("Fruits")) {
            Text("Apple")
            Text("Banana")
            Text("Orange")
        }
        
        Section(header: Text("Vegetables")) {
            Text("Carrot")
            Text("Broccoli")
            Text("Lettuce")
        }
        
        Section(header: Text("Dairy")) {
            Text("Milk")
            Text("Cheese")
            Text("Yogurt")
        }
    }
}

struct CustomViews_Previews: PreviewProvider {
    static var previews: some View {
        @State var d1: String = ""
        @State var d2: String = ""
        //        CustomTF(filler_text: "Test", text_binding: $preview_text)
        //        CustomPF(filler_text: "test", text_binding: $preview_text)
        changeEmailView(newEmail: $d1, pwd: $d2)
    }
}
