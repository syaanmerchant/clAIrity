//
//  CardView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct CardView: View {
    var title: String
    var subtitle: String?
    var content: String
    var isChecklist: Bool = false
    var isWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: iconForTitle(title))
                    .font(.title3)
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Content
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var accentColor: Color {
        if isWarning {
            return .red
        } else if title.contains("Red Flags") || title.contains("Bad") {
            return .red
        } else if title.contains("Medications") {
            return .purple
        } else if title.contains("Timeline") {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var cardBackgroundColor: Color {
        if isWarning {
            return Color.red.opacity(0.05)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private func iconForTitle(_ title: String) -> String {
        if title.contains("Understanding") {
            return "doc.text.magnifyingglass"
        } else if title.contains("Do") {
            return "checklist"
        } else if title.contains("Medications") {
            return "pills"
        } else if title.contains("Timeline") {
            return "calendar"
        } else if title.contains("Recovery") {
            return "heart.text.square"
        } else if title.contains("Questions") {
            return "questionmark.circle"
        } else {
            return "doc.text"
        }
    }
}
