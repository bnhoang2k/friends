//
//  FriendsListView.swift
//  friends
//
//  Created by Bryan Hoang on 10/11/24.
//

import SwiftUI

struct FriendsListView: View {
    
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var nvm: NotificationViewModel
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchText: String = ""
    @State private var showAddFriendView: Bool = false
    
    let dummyData = [
        "Alice Johnson", "Bob Smith", "Charlie Brown", "David Williams", "Emma Thomas", "Frank White", "Grace Lee",
        "Hannah Scott", "Ian Clark", "Jack Morgan", "Katie Bell", "Liam Miller", "Mia Davis", "Noah Wilson", "Olivia Martinez", "Paul Walker", "Quinn Adams", "Rachel Moore", "Sam Harris",
        "Tina Brown", "Umar Khan", "Violet Ray", "Will Turner", "Xander Lee", "Yara Singh", "Zack Collins", "Amy Brooks", "Brian Jenkins", "Cathy Owens", "Daniel Carter", "Evelyn Ross", "Fred Stone",
        "George Baker", "Harper Young", "Isla Green", "James Reed", "Kara Foster", "Leo Perry", "Megan Stewart", "Nina Scott", "Oscar Hughes", "Penny Ford", "Quincy Webb", "Riley Cooper", "Sophia Hayes",
        "Tommy Grant", "Uma Patel", "Victor Lane", "Wendy Shaw", "Xavier Cruz", "Yvonne Mitchell", "Zoe Gray", "Aaron West", "Bethany Morris", "Caleb Jenkins", "Diana Hughes", "Ethan Price", "Fiona Kelly",
        "Gavin Morgan", "Holly Brown", "Isaac Lee", "Jenna Cooper", "Kyle Evans", "Laura Clark", "Mason Hill", "Natalie Adams", "Owen Parker", "Phoebe Collins", "Quinn Richards", "Ryan Scott", "Sienna Thompson",
        "Travis Murphy", "Ursula Carter", "Vince Rogers", "Willow Baker", "Xena Lowe", "Yusuf Allen", "Zara Graham", "Alex King", "Bailey Anderson", "Cody Bryant", "Daisy Clark", "Eli Carter", "Faith Watson",
        "Grant Hall", "Hailey Adams", "Ian Foster", "Jade Peterson", "Kevin Green", "Lily Gray", "Maddox Lee", "Nora Walker", "Omar Price"
    ]
    
    var filteredData: [String] {
        if searchText.isEmpty {
            return dummyData
        } else {
            return dummyData.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredData, id: \.self) { name in
                Text(name)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, 
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search friends")
        }
        .navigationTitle("Friends List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddFriendView.toggle()
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .font(.callout)
                        .tint(.primary)
                }
            }
        }
        .sheet(isPresented: $showAddFriendView, content: {
            SearchBarView()
                .environmentObject(tvm)
                .environmentObject(nvm)
        })
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(TypesenseVM())
            .environmentObject(NotificationViewModel())
    }
}
