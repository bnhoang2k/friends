//
//  AddHangoutView.swift
//  friends
//
//  Created by Bryan Hoang on 10/16/24.
//

import SwiftUI

struct AddHangoutView: View {
    @EnvironmentObject private var svm: SocialVM
    @State private var hangout: Hangout = Hangout.defaultHangout()
    @State private var searchText: String = ""
    let accessType: AccessType
    
    var body: some View {
        TabView {
            if accessType == .fromMain {
                FromMainView(searchText: $searchText, hangout: $hangout)
                    .environmentObject(svm)
            } else if accessType == .fromFriend {
                FromFriendView()
            }
            FormView(hangout: $hangout)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .tint(.primary)
    }
}

struct FromMainView: View {
    @EnvironmentObject private var svm: SocialVM
    @Binding var searchText: String
    @Binding var hangout: Hangout
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search friends", text: $searchText)
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
                    .padding(.horizontal)
                    .padding(.top)
                
                List(svm.filteredFriends(query: searchText, returnEmptyIfNoQuery: true), id: \ .uid) { friend in
                    HStack {
                        ImageView(urlString: friend.photoURL, pictureWidth: 40)
                        VStack(alignment: .leading) {
                            Text(friend.fullName ?? "Unknown Name")
                                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textHeader))
                            Text(friend.username ?? "@unknown")
                                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if hangout.participants.contains(friend.uid) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if let index = hangout.participants.firstIndex(of: friend.uid) {
                                hangout.participants.remove(at: index)
                            } else {
                                hangout.participants.append(friend.uid)
                            }
                        }
                    }
                }.listStyle(.plain)
                
                SelectedFriendsView(participantIds: $hangout.participants)
                    .environmentObject(svm)
                    .padding([.horizontal, .bottom])
            }
        }
    }
}

struct SelectedFriendsView: View {
    @Binding var participantIds: [String]
    @EnvironmentObject var svm: SocialVM
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(participantIds, id: \.self) { participantId in
                    if let friend = svm.getFriendFromID(participantId) {
                        HStack {
                            ImageView(urlString: friend.photoURL, pictureWidth: 30)
                                .clipShape(Circle())
                            Text(friend.username ?? "@unknown")
                                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textHeader))
                                .foregroundColor(.primary)
                            Button(action: {
                                withAnimation(.spring()) {
                                    if let index = participantIds.firstIndex(of: participantId) {
                                        participantIds.remove(at: index)
                                    }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
                    }
                }
            }
        }
    }
}

struct FromFriendView: View {
    var body: some View {
        HStack {}
    }
}

struct FormView: View {
    @Binding var hangout: Hangout
    
    var wordCount: Int {
        return hangout.description?.split { $0.isWhitespace }.count ?? 0
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                DatePicker("Date", selection: $hangout.date, displayedComponents: .date)
                    .padding(5)
            }
            Section(header: Text("Vibe")) {
                Slider(value: Binding(
                    get: { Double(Hangout.HangoutVibe.allCases.firstIndex(of: hangout.vibe) ?? 0) },
                    set: { newValue in hangout.vibe = Hangout.HangoutVibe.allCases[Int(newValue)] }
                ), in: 0...Double(Hangout.HangoutVibe.allCases.count - 1))
                .contentShape(Rectangle()) // Extend the clickable area to the entire slider box
                Text("\(hangout.vibe.description)")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section(header: Text("Details")) {
                HStack {
                    Text("\(hangout.duration.description)")
                    Slider(value: Binding(
                        get: { Double(Hangout.HangoutDuration.allCases.firstIndex(of: hangout.duration) ?? 0) },
                        set: { newValue in hangout.duration = Hangout.HangoutDuration.allCases[Int(newValue)] }
                    ), in: 0...Double(Hangout.HangoutDuration.allCases.count - 1))
                }
                Stepper("Budget: $\(hangout.budget, specifier: "%.2f")", value: $hangout.budget, in: 0...1000, step: 5)
                Toggle("Outdoors?", isOn: $hangout.isOutdoor)
                VStack(alignment: .leading) {
                    TextEditor(text: Binding(
                        get: { hangout.description ?? "" },
                        set: { newValue in
                            let words = newValue.split { $0.isWhitespace }
                            if words.count <= 100 {
                                hangout.description = newValue
                            } else {
                                // Limit the text to 100 words
                                hangout.description = words.prefix(100).joined(separator: " ")
                            }
                        }
                    ))
                    .frame(height: 100)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(wordCount > 50 ? .red : Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Character and word count
                    Text("\(wordCount) / 25 words")
                        .foregroundColor(wordCount > 50 ? .red : .gray) // Tint red if word count exceeds 50
                        .padding(.top, 4)
                    Button {
                        
                    } label: {
                        Text("Generate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 10)
            }
        }
        .scrollContentBackground(.hidden)
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
    }
}


extension AddHangoutView {
    enum AccessType {
        case fromMain
        case fromFriend
    }
}

#Preview {
    AddHangoutView(accessType: .fromMain)
        .environmentObject(SocialVM())
}
