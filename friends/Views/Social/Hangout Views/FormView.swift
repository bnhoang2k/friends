//
//  FormView.swift
//  friends
//
//  Created by Bryan Hoang on 11/9/24.
//

import SwiftUI

struct FormView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @Binding var hangout: Hangout
    @Binding var selectedTab: Int
    
    private var wordCount: Int {
        return hangout.description?.split { $0.isWhitespace }.count ?? 0
    }
    
    var body: some View {
        Form {
            BasicInformationSection(date: $hangout.date)
            VibesSection(vibe: $hangout.vibe)
            DetailsSection(hangout: $hangout, wordCount: wordCount)
            GenerateButtonSection(hangout: $hangout, avm: avm, svm: svm, selectedTab: $selectedTab)
        }
        .scrollContentBackground(.hidden)
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .onTapGesture { dismissKeyboard() }
    }
}

private struct BasicInformationSection: View {
    @Binding var date: Date
    
    var body: some View {
        Section("Basic Information") {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .padding(5)
        }
    }
}

private struct VibesSection: View {
    @Binding var vibe: Hangout.HangoutVibe
    
    var body: some View {
        Section("Vibes") {
            Slider(value: Binding(
                get: { Double(Hangout.HangoutVibe.allCases.firstIndex(of: vibe) ?? 0) },
                set: { newValue in vibe = Hangout.HangoutVibe.allCases[Int(newValue)] }
            ), in: 0...Double(Hangout.HangoutVibe.allCases.count - 1))
            .contentShape(Rectangle())
            
            Text("\(vibe.description)")
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct DetailsSection: View {
    @Binding var hangout: Hangout
    var wordCount: Int
    
    var body: some View {
        Section("Details") {
            HStack {
                Text("\(hangout.duration.description)")
                Slider(value: Binding(
                    get: { Double(Hangout.HangoutDuration.allCases.firstIndex(of: hangout.duration) ?? 0) },
                    set: { newValue in hangout.duration = Hangout.HangoutDuration.allCases[Int(newValue)] }
                ), in: 0...Double(Hangout.HangoutDuration.allCases.count - 1))
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
        }
    }
}

private struct GenerateButtonSection: View {
    @Binding var hangout: Hangout
    var avm: AuthenticationVM
    var svm: SocialVM
    @Binding var selectedTab: Int
    
    var body: some View {
            Button {
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
    FormView(hangout: Binding(get: {
        hangout
    }, set: { newValue in
        hangout = newValue
    }), selectedTab: .constant(0))
    .environmentObject(AuthenticationVM())
    .environmentObject(SocialVM())
}
