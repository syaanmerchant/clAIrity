//
//  ExtractionMedication.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-11.
//

import Foundation

struct ExtractedMedication: Codable, Identifiable, Hashable {
    var id: UUID = UUID()

    let name: String
    let strength: String?
    let form: String?
    let route: String?
    let frequency: String?
    let duration: String?
    let instructions: String?

    // Exclude `id` from JSON decoding/encoding
    enum CodingKeys: String, CodingKey {
        case name, strength, form, route, frequency, duration, instructions
    }
}

struct MedListJSON: Codable {
    let medications: [ExtractedMedication]
}

