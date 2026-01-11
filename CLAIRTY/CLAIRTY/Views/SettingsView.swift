//
//  SettingsView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedLanguage = "en"

    var body: some View {
        Form {
            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("en")
                Text("Spanish").tag("es")
                // Add more as needed
            }
            // Integrate with TranslationService if needed
        }
        .navigationTitle("Settings")
    }
}
