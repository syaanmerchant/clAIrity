//
//  Extensions.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Foundation

extension String {
    // Helper to trim whitespace
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Simple keyword extraction (for basic NLP fallbacks)
    func extractKeywords() -> [String] {
        // Basic split and filter; enhance with NLP if needed
        self.lowercased().split(whereSeparator: { !$0.isLetter }).map { String($0) }.filter { $0.count > 2 }
    }
}

extension Date {
    // Helper to add days
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
