//
//  TestFunctions.swift
//  friends
//
//  Created by Bryan Hoang on 8/30/24.
//

import SwiftUI

struct TestFunctions: View {
    
    @EnvironmentObject var avm: AuthenticationVM
    
    var body: some View {
        Button {
            do {
                print(avm.user ?? "Error")
            }
        } label: {
            Text("Print Authenticated User Data")
        }
    }
}

#Preview {
    NavigationStack {
        TestFunctions()
    }
}
