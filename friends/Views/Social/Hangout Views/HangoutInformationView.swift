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
                HangoutLocationSection(hangout: $hangout,
                                       isEditing: $isEditing)
                
                FriendSection(hangout: $hangout)
                
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
                
                if let description = hangout.description, !description.isEmpty {
                    NotesSection(notes: description)
                }
                
                UserPhotoSection(hangout: $hangout)
            }
        }
        .padding()
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing.toggle()
                } label: {
                    Text("Edit")
                }
                
            }
        }
        .sheet(isPresented: $isEditing) {
            EditForm(hangout: $hangout,
                     isEditing: $isEditing,
                     isInvalid: .constant(isInvalid))
        }
    }
}

private struct EditForm: View {
    
    @Binding var hangout: Hangout
    @Binding var isEditing: Bool
    @Binding var isInvalid: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                HangoutLocationSection(hangout: $hangout,
                                       isEditing: $isEditing)
                ExpandableDatePicker(title: "Start Time",
                                     date: $hangout.startDate,
                                     isInvalid: $isInvalid)
                ExpandableDatePicker(title: "End Time",
                                     date: $hangout.endDate,
                                     isInvalid: $isInvalid)
                
            }
        }
        .padding()
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

private struct HangoutLocationSection: View {
    
    @Binding var hangout: Hangout
    @Binding var isEditing: Bool
    
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
                            if isEditing == false {
                                guard let displayName = hangout.location?.name else {
                                    return
                                }
                                Utilities.shared.openBusinessInAppleMaps(name: displayName,
                                                                         near: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                            }
                            else {
                                showManualMap.toggle()
                            }
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
    
    private struct AnimatedMapView: View {
        let coordinate: CLLocationCoordinate2D
        
        var body: some View {
            GeometryReader { geometry in
                MapView(coordinate: coordinate)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
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

struct ExpandableDatePicker: View {
    let title: String
    @Binding var date: Date? // Binding to parent date
    @Binding var isInvalid: Bool
    
    @State private var isExpanded: Bool = false
    @State private var tempDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("\(title):")
                    Spacer()
                    Text("\(date?.formatted(date: .abbreviated, time: .shortened) ?? "Not Set")")
                }
                .foregroundColor(isInvalid ? .red : .primary)
                .contentShape(Rectangle())
            }
            
            if isExpanded {
                DatePicker(
                    "Select \(title)",
                    selection: $tempDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(isInvalid ? .red : .primary)
                .transition(Self.datePickerTransition)
            }
        }
        .onChange(of: tempDate) { newValue in
            date = newValue
        }
    }
    
    static var datePickerTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.95, anchor: .top))
                .animation(.easeInOut(duration: 0.3)),
            removal: .opacity
                .combined(with: .scale(scale: 0.95, anchor: .top))
                .animation(.easeOut(duration: 0.3))
        )
    }
}

private struct NotesSection: View {
    var notes: String

    var body: some View {
        VStack(spacing: 15) {
            // Notes Display
            VStack(alignment: .leading, spacing: 5) {
                Text("Notes")
                    .font(.headline)

                Text(notes.isEmpty ? "No notes available." : notes)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
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
