//
//  HangoutInformationView.swift
//  friends
//
//  Created by Bryan Hoang on 12/16/24.
//

import SwiftUI
import MapKit

struct HangoutInformationView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    
    @Binding var hangout: Hangout
    @State private var isEditing: Bool = false
    
    private var isInvalid: Bool {
        if let startDate = hangout.startDate, let endDate = hangout.endDate {
            return startDate >= endDate
        } else {
            return false
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                HangoutLocationSection(hangout: $hangout)
                FriendSection(hangout: $hangout)
                TimeSection(hangout: $hangout,
                            isInvalid: .constant(isInvalid))
                DetailSection(hangout: $hangout)
                UserPhotoSection(hangout: $hangout)
            }
        }
        .padding()
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isEditing.toggle() } label: { Text("Edit") }
            }
        }
        .tint(.primary)
        .sheet(isPresented: $isEditing) {
            HangoutInformationEditView(hangout: $hangout,
                                       isInvalid: .constant(isInvalid))
        }
    }
}

private struct HangoutLocationSection: View {
    
    @Binding var hangout: Hangout
    
    @State private var isExpanded: Bool = true
    @State private var showManualMap: Bool = false
    
    var body: some View {
        Group {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let lat = hangout.location?.latitude, let lng = hangout.location?.longitude {
                    AnimatedMapView(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        .padding(.top)
                        .frame(height: 200) // Fixed height
                        .cornerRadius(12)
                        .mask(
                            Rectangle()
                                .frame(height: isExpanded ? 200 : 0) // Control visibility
                                .offset(y: isExpanded ? 0 : -200) // Animate upwards on collapse
                                .animation(.easeInOut(duration: 0.4), value: isExpanded) // Smooth animation
                        )
                        .onTapGesture {
                            guard let displayName = hangout.location?.name else {
                                return
                            }
                            Utilities.shared.openBusinessInAppleMaps(name: displayName,
                                                                     near: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }
                }
            } label: {
                HStack {
                    Text(hangout.location?.name ?? "Location Name Error")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showManualMap) {
            MapSearchView(initialCoordinate: CLLocationCoordinate2D(latitude: hangout.location?.latitude ?? 0,
                                                                    longitude: hangout.location?.longitude ?? 0)) { name, coordinate in
                hangout.location = Location(name: name, coordinate: coordinate)
            }
        }
    }
}

struct AnimatedMapView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        GeometryReader { geometry in
            MapView(coordinate: coordinate)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct FriendSection: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @Binding var hangout: Hangout
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(hangout.participantIds.filter{ $0 != avm.user?.uid ?? "" }, id: \.self) { participantId in
                    if let friend = svm.getFriendFromID(participantId) {
                        HStack {
                            ImageView(urlString: friend.photoURL, pictureWidth: 10)
                            Text(friend.fullName ?? "Name ERROR")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

private struct TimeSection: View {
    
    @Binding var hangout: Hangout
    @Binding var isInvalid: Bool
    
    var body: some View {
        Group {
            HStack {
                Text("Start Time:")
                Spacer()
                Text("\(hangout.startDate?.formatted(date: .abbreviated, time: .shortened) ?? "Not Set")")
            }
            HStack {
                Text("End Time:")
                Spacer()
                Text("\(hangout.endDate?.formatted(date: .abbreviated, time: .shortened) ?? "Not Set")")
            }
        }
        .foregroundColor(isInvalid ? .red : .primary)
    }
}

private struct DetailSection: View {
    
    @Binding var hangout: Hangout
    
    var body: some View {
        Group {
            HStack {
                Text("Hangout Vibe:")
                Spacer()
                Label("\(hangout.vibe.rawValue)", systemImage: hangout.vibe.symbolName)
            }
            
            HStack {
                Text("Hangout Status:")
                Spacer()
                Text("\(hangout.status.rawValue)")
            }
            
            HStack {
                Text("Money Spent:")
                Spacer()
                Text("\(hangout.budget, specifier: "%.2f")")
            }
        }
    }
}

private struct UserPhotoSection: View {
    
    @Binding var hangout: Hangout
    
    var body: some View {
        if let hangoutPhotos = hangout.userPictures {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(hangoutPhotos, id: \.self) { photoURL in
                        ImageView(urlString: photoURL, pictureWidth: 500)
                    }
                }
            }
        }
    }
}

#Preview {
    var hangout = Hangout.defaultHangout()
    NavigationStack {
        HangoutInformationView(hangout: Binding(get: {
            hangout
        }, set: { newValue in
            hangout = newValue
        }))
    }
}
