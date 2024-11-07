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
                    .padding(10)
                    .padding(.leading, 30)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
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
                                .font(.headline)
                            Text(friend.username ?? "@unknown")
                                .font(.subheadline)
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
                                .font(.subheadline)
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
    @State private var sliderValue: Double = 0.5 // Initial value for slider
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Participants")) {
                    Text("Selected Friends: \(hangout.participants.joined(separator: ", "))")
                }
                
                Section(header: Text("Basic Information")) {
                    DatePicker("Date", selection: $hangout.date, displayedComponents: .date)
                    Picker("Duration", selection: $hangout.duration) {
                        ForEach(Hangout.HangoutDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue.capitalized).tag(duration)
                        }
                    }
                }
                
                Section(header: Text("Vibe")) {
                    Slider(value: Binding(
                        get: { Double(Hangout.HangoutVibe.allCases.firstIndex(of: hangout.vibe) ?? 0) },
                        set: { newValue in hangout.vibe = Hangout.HangoutVibe.allCases[Int(newValue)] }
                    ), in: 0...Double(Hangout.HangoutVibe.allCases.count - 1))
                    .contentShape(Rectangle()) // Extend the clickable area to the entire slider box
                    .padding(.vertical, 30) // Increase vertical padding to enlarge hitbox
                    .frame(height: 60) // Increase frame height to make slider easier to interact with
                    Text("\(hangout.vibe.description)")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Details")) {
                    TextField("Location (Optional)", text: Binding(
                        get: { hangout.location ?? "" },
                        set: { hangout.location = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Description (Optional)", text: Binding(
                        get: { hangout.description ?? "" },
                        set: { hangout.description = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Tags (comma separated)", text: Binding(
                        get: { hangout.tags?.joined(separator: ", ") ?? "" },
                        set: { hangout.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    Stepper("Budget: $\(hangout.budget, specifier: "%.2f")", value: $hangout.budget, in: 0...1000, step: 5)
                    Toggle("Is Outdoor Hangout", isOn: $hangout.isOutdoor)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
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
