//
//  FormView.swift
//  friends
//
//  Created by Bryan Hoang on 11/9/24.
//

import SwiftUI
import MapKit

struct FormView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @Binding var hangout: Hangout
    
    private var wordCount: Int {
        return hangout.description?.split { $0.isWhitespace }.count ?? 0
    }
    
    var body: some View {
        Form {
            BasicInformationSection(date: $hangout.creationDate)
            VibesSection(vibe: $hangout.vibe)
            DetailsSection(hangout: $hangout, wordCount: wordCount)
        }
        .scrollContentBackground(.hidden)
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
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
    @Binding var vibe: HangoutVibe
    
    var body: some View {
        Section("Vibes") {
            Slider(value: Binding(
                get: { Double(HangoutVibe.allCases.firstIndex(of: vibe) ?? 0) },
                set: { newValue in vibe = HangoutVibe.allCases[Int(newValue)] }
            ), in: 0...Double(HangoutVibe.allCases.count - 1))
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
}
