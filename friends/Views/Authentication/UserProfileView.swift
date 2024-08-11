//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @StateObject var upvm: UserProfileVM = UserProfileVM()
    
    var body: some View {
        NavigationStack {
            List {
                change_tf(field_name: "Email", image_name: "envelope", field_value: $upvm.string1)
                // TODO: Add password.
            }
            .onAppear {
                upvm.resetFields()
            }
        }
    }
}

extension UserProfileView {
    private func change_tf(field_name: String,
                           image_name: String,
                           field_value: Binding<String>,
                           secure_field: Bool? = nil) -> some View {
        
        NavigationLink {
//            ChangeFieldView(field_name: field_name, field_value: field_value, secure_field: secure_field)
        } label: {
            HStack {
                Label("\(field_name)", systemImage: "\(image_name)")
                Spacer()
                if secure_field != nil {Text("\(field_value.wrappedValue)")}
            }
        }
        
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
