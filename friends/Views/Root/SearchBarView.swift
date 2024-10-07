//
//  SearchBarView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI

struct SearchBarView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    
    var body: some View {
        NavigationStack {
            // Main content here
            List(tvm.searchResults, id: \.uid) { user in
                HStack {
                    ImageView(urlString: user.photoURL, pictureWidth: 50)
                    VStack(alignment: .leading) {
                        Text(user.username ?? "username error")
                        Text(user.fullName ?? "full name error")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        TextField("Search", text: $tvm.searchText)
                            .frame(maxWidth: .infinity)
                            .textFieldStyle(.plain)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
        .onChange(of: presentationMode.wrappedValue.isPresented) { isPresented in
            if !isPresented {
                UIApplication.shared.dismissKeyboard()
            }
        }
        .onChange(of: tvm.searchText, perform: { value in
            Task {
                await tvm.searchUsers(query: tvm.searchText,excludedName: avm.user?.username ?? "Error")
            }
        })
        .onDisappear {
            tvm.searchText = ""
            tvm.searchResults = []
        }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        SearchBarView()
            .environmentObject(TypesenseVM())
            .environmentObject(AuthenticationVM())
    }
}
