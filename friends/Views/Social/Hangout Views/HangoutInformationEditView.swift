//
//  HangoutInformationEditView.swift
//  friends
//
//  Created by Bryan Hoang on 12/30/24.
//

import SwiftUI
import MapKit

struct HangoutInformationEditView: View {
    @Binding var hangout: Hangout
    @Binding var isInvalid: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                HangoutLocationEditSection(hangout: $hangout)
                TimeEditSection(hangout: $hangout,
                                isInvalid: $isInvalid)
                DetailsEditSection(hangout: $hangout)
            }
        }
        .padding()
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

private struct HangoutLocationEditSection: View {
    
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
                            showManualMap.toggle()
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

private struct TimeEditSection: View {
    
    @Binding var hangout: Hangout
    @Binding var isInvalid: Bool
    var body: some View {
        Group {
            ExpandableDatePicker(title: "Start Time",
                                 date: $hangout.startDate,
                                 isInvalid: $isInvalid)
            ExpandableDatePicker(title: "End Time",
                                 date: $hangout.endDate,
                                 isInvalid: $isInvalid)
        }
    }
}

private struct ExpandableDatePicker: View {
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

private struct DetailsEditSection: View {
    
    @Binding var hangout: Hangout
    
    var body: some View {
        Group {
            // Hangout Vibe
            SmoothSnappingSliderWithState(hangout: $hangout)
            
            // Hangout Status
            HStack {
                Text("Status:")
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(HangoutStatus.allCases, id: \.self) { status in
                        Button {
                            hangout.status = status
                        } label: {
                            HStack {
                                Text(status.rawValue.capitalized)
                                if status == hangout.status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(hangout.status.rawValue.capitalized)
                        .foregroundColor(.primary)
                }
            }
            
            // Money Spent or Budget
            Stepper("Money Spent: $\(hangout.budget, specifier: "%.2f")",
                    value: $hangout.budget, in: 0...1000, step: 5)
        }
    }
}

struct SmoothSnappingSliderWithState: View {
    @State private var sliderValue: Double = 0.0 // Holds the slider's state
    @Binding var hangout: Hangout
    
    var body: some View {
        VStack {
            Slider(value: $sliderValue)
                .onChange(of: sliderValue) { newValue in
                    // Dynamically update the vibe based on the slider's value
                    hangout.vibe = hangout.getHangoutVibe(for: newValue)
                }
            // Display the current vibe
            Label(hangout.vibe.description, systemImage: hangout.vibe.symbolName)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            // Sync the slider position with the initial vibe value
            sliderValue = hangout.getInitialSliderValue(for: hangout.vibe)
        }
        .onDisappear(perform: {
            hangout.vibe = hangout.getHangoutVibe(for: sliderValue)
        })
        .frame(height: 75)
    }
}
