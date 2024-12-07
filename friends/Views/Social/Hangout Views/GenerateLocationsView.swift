//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI
import MarkdownUI

struct GenerateLocationsView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    onGenerateTapped()
                } label: {
                    Text("Renegerate")
                }

            }
            List {
                if vvm.inProgress {
                    ProgressView()
                }
                Markdown("\(vvm.outputText)")
            }
            .listRowSeparator(.hidden)
            .listStyle(.plain)
        }
        .onTapGesture {dismissKeyboard()}
        .padding()
    }
}

extension GenerateLocationsView {
    func onGenerateTapped() {
      Task {
          vvm.userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                                cachedFriendsList: svm.cachedFriendsList)
          print(vvm.userInput)
          await vvm.reason()
      }
    }
}

private struct GenerateButtonSection: View {
    @Binding var userInput: String
    @Binding var hangout: Hangout
    var avm: AuthenticationVM
    var svm: SocialVM
    @Binding var selectedTab: Int
    
    var body: some View {
            Button {
                userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                      cachedFriendsList: svm.cachedFriendsList)
                selectedTab = 2
            } label: {
                Text("Generate")
                    .frame(maxWidth: .infinity)
                    .padding([.horizontal])
            }
            .buttonStyle(.borderless)
    }
}

#Preview {
    var hangout = Hangout.defaultHangout()
    GenerateLocationsView(vvm: VertexViewModel(), hangout: Binding(get: {
        hangout
    }, set: { newValue in
        hangout = newValue
    }))
    .environmentObject(AuthenticationVM())
    .environmentObject(SocialVM())
}
