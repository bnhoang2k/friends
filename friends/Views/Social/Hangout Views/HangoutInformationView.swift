//
//  HangoutInformationView.swift
//  friends
//
//  Created by Bryan Hoang on 12/16/24.
//

import SwiftUI

struct HangoutInformationView: View {
    @Binding var hangout: Hangout
    
    @State private var startInvalid: Bool = false
    @State private var endInvalid: Bool = false
    @State private var descriptionExpanded: Bool = true
    @State private var budgetExpanded: Bool = true
    
    // Dynamically check the validity of the interval
    func updateInvalidStates() {
        if let startDate = hangout.startDate, let endDate = hangout.endDate {
            startInvalid = startDate > endDate
            endInvalid = startDate > endDate
        } else {
            startInvalid = false
            endInvalid = false
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    
                    // Location Section
                    HStack {
                        Text(hangout.location ?? "Location Name Error")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("Actual Location Coordinates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Start Date Section
                    ExpandableDatePicker(
                        title: "Start Time",
                        date: $hangout.startDate,
                        isInvalid: $startInvalid
                    )
                    
                    // End Date Section
                    ExpandableDatePicker(
                        title: "End Time",
                        date: $hangout.endDate,
                        isInvalid: $endInvalid
                    )
                    
                    // Description Section
                    if ((hangout.description?.isEmpty) == nil) {
                        DisclosureGroup("Description", isExpanded: $descriptionExpanded) {
                            Text(hangout.description ?? """
                            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua...
                            """)
                            .font(.body)
                            .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: hangout.startDate) { newValue in
                print("Start Date updated to: \(newValue?.description ?? "nil")")
                updateInvalidStates()
            }
            .onChange(of: hangout.endDate) { newValue in
                print("End Date updated to: \(newValue?.description ?? "nil")")
                updateInvalidStates()
            }
            .navigationTitle(hangout.title ?? "No Title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ExpandableDatePicker: View {
    let title: String
    @Binding var date: Date? // Binding to parent date
    @Binding var isInvalid: Bool
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("\(title): \(date?.formatted(date: .abbreviated, time: .shortened) ?? "Not Set")")
                        .bold()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(isInvalid ? .red : .primary)
                .contentShape(Rectangle())
            }
            
            if isExpanded {
                DatePicker(
                    "Select \(title)",
                    selection: Binding(
                        get: { date ?? Date() }, // Provide a default value
                        set: { newValue in
                            date = newValue // Propagate changes back
                        }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(isInvalid ? .red : .primary)
                .transition(Self.datePickerTransition)
            }
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
