//
//  FormView.swift
//  friends
//
//  Created by Bryan Hoang on 11/9/24.
//

import SwiftUI

struct FormView: View {
    @Binding var hangout: Hangout
    
    private var wordCount: Int {
        return hangout.description?.split { $0.isWhitespace }.count ?? 0
    }
    
    private var disableGenerateButton: Bool {
        return hangout.participants.count <= 1 || wordCount >= 50
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Basic Information")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    DatePicker("Date", selection: $hangout.date, displayedComponents: .date)
                        .padding(5)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vibe")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Slider(value: Binding(
                        get: { Double(Hangout.HangoutVibe.allCases.firstIndex(of: hangout.vibe) ?? 0) },
                        set: { newValue in hangout.vibe = Hangout.HangoutVibe.allCases[Int(newValue)] }
                    ), in: 0...Double(Hangout.HangoutVibe.allCases.count - 1))
                    .contentShape(Rectangle()) // Extend the clickable area to the entire slider box
                    
                    Text("\(hangout.vibe.description)")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    HStack {
                        Text("\(hangout.duration.description)")
                        Slider(value: Binding(
                            get: { Double(Hangout.HangoutDuration.allCases.firstIndex(of: hangout.duration) ?? 0) },
                            set: { newValue in hangout.duration = Hangout.HangoutDuration.allCases[Int(newValue)] }
                        ), in: 0...Double(Hangout.HangoutDuration.allCases.count - 1))
                    }
                    
                    Stepper("Budget: $\(hangout.budget, specifier: "%.2f")", value: $hangout.budget, in: 0...1000, step: 5)
                    Toggle("Outdoors?", isOn: $hangout.isOutdoor)
                    
                    VStack(alignment: .leading) {
                        TextEditor(text: Binding(
                            get: { hangout.description ?? "" },
                            set: { newValue in
                                let words = newValue.split { $0.isWhitespace }
                                if words.count <= 100 {
                                    hangout.description = newValue
                                } else {
                                    // Limit the text to 100 words
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
                            .foregroundColor(wordCount > 50 ? .red : .gray) // Tint red if word count exceeds 50
                            .padding(.top, 4)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button {
                    print(hangout.participants)
                } label: {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding([.horizontal])
                        .tint(disableGenerateButton ? Color(UIColor.systemGray) : Color.primary)
                        .opacity(disableGenerateButton ? 0.5 : 1.0)
                }
                .buttonStyle(.bordered)
                .disabled(disableGenerateButton)
                
                Spacer()
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .onTapGesture {
            dismissKeyboard()
        }
    }
}
