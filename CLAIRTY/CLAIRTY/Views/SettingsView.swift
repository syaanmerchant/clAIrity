//
//  SettingsView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("languageCode") private var selectedLanguage = "en"

    var body: some View {
        Form {
            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("en")
                Text("Spanish").tag("es")
                Text("French").tag("fr")
                Text("Hindi").tag("hi")
                Text("Punjabi").tag("pa")
                Text("Urdu").tag("ur")
            }
        }
        .navigationTitle("Settings")
    }
}
