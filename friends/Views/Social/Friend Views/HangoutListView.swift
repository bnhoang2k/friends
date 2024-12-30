//
//  HangoutListView.swift
//  friends
//
//  Created by Bryan Hoang on 12/11/24.
//

import SwiftUI

struct HangoutListView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm : SocialVM
    @Binding var hangoutList: [Hangout]
    @Binding var searchText: String
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    SearchBar(placeholderText: "Search Hangouts", searchText: $searchText)
                    Button {
                        
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease")
                    }
                }
                .padding([.bottom])
                if !hangoutList.isEmpty {
                    ScrollView(showsIndicators: false) {
                        ForEach(hangoutList.indices, id: \.self) { index in
                            NavigationLink {
                                HangoutInformationView(hangout: $hangoutList[index])
                                    .environmentObject(avm)
                                    .environmentObject(svm)
                            } label: {
                                HangoutCardView(hangout: hangoutList[index])
                            }
                        }
                    }
                }
                else {
                    Spacer()
                }
            }
            .padding()
        }
        .tint(.primary)
        .navigationTitle("Hangouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HangoutCardView: View {
    let hangout: Hangout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hangout.location?.name ?? "Unknown Location")
                    .font(.headline)
                Spacer()
                Text(hangout.creationDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let description = hangout.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .cornerRadius(12)
    }
}
