//
//  FormView.swift
//  friends
//
//  Created by Bryan Hoang on 11/9/24.
//

import SwiftUI

struct FormView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @EnvironmentObject private var vvm: VertexViewModel
    @Binding var hangout: Hangout
    
    @State private var showLocationOptionsView: Bool = false
    @State private var showManualMap: Bool = false
    @State private var showGenerateLocations: Bool = false
    
    private var wordCount: Int {
        return hangout.description?.split { $0.isWhitespace }.count ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BasicInformationSection(date: $hangout.creationDate)
                LocationInformationSection(hangout: $hangout, showLocationOptionsView: $showLocationOptionsView)
                VibesSection(vibe: $hangout.vibe)
                DetailsSection(hangout: $hangout, wordCount: wordCount)
                Button {
                    Task {
                        if let uid = avm.user?.uid {
                            try await svm.createHangout(uid: uid, hangout: hangout)
                            dismiss()
                        }
                    }
                } label: {
                    Text("Add Hangout!")
                }
            }
        }
        .padding()
        .scrollIndicators(.hidden)
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
        .onTapGesture { dismissKeyboard() }
        .sheet(isPresented: $showLocationOptionsView) {
            LocationOptionsView(showManualMap: $showManualMap,
                                showGenerateLocations: $showGenerateLocations)
        }
        .sheet(isPresented: $showManualMap) {
            MapSearchView { name, coordinate in
                hangout.location = Location(name: name, coordinate: coordinate)
            }
        }
        .sheet(isPresented: $showGenerateLocations) {
            GenerateLocationsView(vvm: vvm,
                                  hangout: $hangout)
        }
    }
}

private struct BasicInformationSection: View {
    @Binding var date: Date
    
    var body: some View {
        Section {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .padding(5)
        } header: {
            HStack {
                Text("Basic Information")
                    .font(.headline)
                Spacer()
            }
        }
        
    }
}

private struct LocationInformationSection: View {
    
    @Binding var hangout: Hangout
    @Binding var showLocationOptionsView: Bool
    
    var body: some View {
        Section {
            Button {
                showLocationOptionsView.toggle()
            } label: {
                HStack {
                    if let locationName = hangout.location?.name {
                        Text("\(locationName)")
                    }
                    else {
                        Text("Location Not Selected Yet")
                    }
                    Spacer()
                }
                .tint(.blue)
            }
            .buttonStyle(.borderless)
            .contentShape(.rect)
        } header: {
            HStack {
                Text("Location")
                    .font(.headline)
                Spacer()
            }
        }
    }
}

private struct LocationOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showManualMap: Bool
    @Binding var showGenerateLocations: Bool
    
    var body: some View {
        VStack {
            Button {
                dismiss()
                showManualMap.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mappin")
                        .frame(width: 20, alignment: .center) // Set a fixed width
                    Text("Pick a location")
                    Spacer()
                }
            }
            Button {
                dismiss()
                showGenerateLocations.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.max")
                        .frame(width: 20, alignment: .center) // Same fixed width as above
                    Text("Get Suggestions")
                    Spacer()
                }
            }
            .padding(.top)
        }
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
        .padding(.horizontal)
        .presentationDetents([.fraction(0.15)])
    }
}

private struct VibesSection: View {
    @Binding var vibe: HangoutVibe
    
    var body: some View {
        Section {
            Slider(value: Binding(
                get: { Double(HangoutVibe.allCases.firstIndex(of: vibe) ?? 0) },
                set: { newValue in vibe = HangoutVibe.allCases[Int(newValue)] }
            ), in: 0...Double(HangoutVibe.allCases.count - 1))
            .contentShape(Rectangle())
            Text("\(vibe.description)")
                .frame(maxWidth: .infinity, alignment: .center)
        } header: {
            HStack {
                Text("Vibe")
                    .font(.headline)
                Spacer()
            }
        }
        
    }
}

private struct DetailsSection: View {
    @Binding var hangout: Hangout
    var wordCount: Int
    
    var body: some View {
        Section {
            HStack {
                Text("\(hangout.duration.description)")
                Slider(value: Binding(
                    get: { Double(HangoutDuration.allCases.firstIndex(of: hangout.duration) ?? 0) },
                    set: { newValue in hangout.duration = HangoutDuration.allCases[Int(newValue)] }
                ), in: 0...Double(HangoutDuration.allCases.count - 1))
            }
            
            Stepper("Budget: $\(hangout.budget, specifier: "%.2f")", value: $hangout.budget, in: 0...1000, step: 5)
            
            Toggle("Outdoors?", isOn: $hangout.isOutdoor)
            
            TextEditor(text: Binding(
                get: { hangout.description ?? "" },
                set: { newValue in
                    let words = newValue.split { $0.isWhitespace }
                    if words.count <= 100 {
                        hangout.description = newValue
                    } else {
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
            Text("\(wordCount) / 50 words")
                .foregroundColor(wordCount > 50 ? .red : .gray)
                .padding(.top, 4)
        } header: {
            HStack {
                Text("Details")
                    .font(.headline)
                Spacer()
            }
        }
    }
}

#Preview {
    var hangout = Hangout.defaultHangout()
    FormView( hangout: Binding(get: { hangout
    }, set: { newValue in
        hangout = newValue
    }))
    .environmentObject(AuthenticationVM())
    .environmentObject(SocialVM())
    .environmentObject(VertexViewModel())
}
