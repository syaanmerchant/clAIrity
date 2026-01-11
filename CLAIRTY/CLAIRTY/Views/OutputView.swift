//
//  OutputView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct OutputView: View {
    let output: ProcessedOutput?
    @State private var selectedLanguage = "en"
    @State private var showAfterCare = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Language selector
                HStack {
                    Text("Language:")
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                CardView(
                    title: "Understanding",
                    subtitle: "Here is what this means in plain English",
                    content: output?.simplifiedText ?? "Processing..."
                )
                
                let actionsToShow = resolvedActions(output: output)
                CardView(
                    title: "What You Need To Do",
                    subtitle: "Action checklist",
                    content: formatActions(actionsToShow),
                    isChecklist: true
                )
                
                CardView(
                    title: "Medications",
                    subtitle: "What, when, and how",
                    content: formatMedications(output?.medications ?? [])
                )
                
                CardView(
                    title: "Timeline",
                    subtitle: "Your recovery schedule",
                    content: formatTimeline(output?.timeline ?? [])
                )
                
                CardView(
                    title: "Recovery Signs",
                    subtitle: "What to expect",
                    content: formatSigns(output?.recoverySigns),
                    isWarning: true
                )
                
                CardView(
                    title: "Questions To Ask",
                    subtitle: "Be prepared for your next visit",
                    content: formatQuestions(output?.questions ?? [])
                )
                
                NavigationLink(destination: AfterCareView(output: output), isActive: $showAfterCare) {
                    HStack {
                        Image(systemName: "heart.text.square")
                        Text("View After-Care Plan")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.top)
                
                // Process Another Document Button
                Button(action: {
                    dismiss() // Dismiss back to ProcessingView (or InputView depending on your navigation stack)
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Process Another Document")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 5)
                .padding(.bottom, 30)
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatActions(_ actions: [String]) -> String {
        if actions.isEmpty {
            return "No specific actions identified. Follow your healthcare provider's instructions."
        }
        return actions.map { "• " + $0 }.joined(separator: "\n")
    }
    
    private func formatMedications(_ meds: [Medication]) -> String {
        if meds.isEmpty {
            return "No medications identified in your documents."
        }
        var result = ""
        for med in meds {
            result += "Name: \(med.name)\n"
            result += "Dosage: \(med.dosage)\n"
            result += "Duration: \(med.duration)\n"
            result += "Notes: \(med.notes)\n"
            result += "---\n"
        }
        return result
    }
    
    private func formatTimeline(_ items: [TimelineItem]) -> String {
        if items.isEmpty {
            return "No timeline information available."
        }
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for (index, item) in items.enumerated() {
            result += "Day \(index + 1) (\(dateFormatter.string(from: item.date))):\n"
            result += item.tasks.joined(separator: ", ")
            result += "\n\n"
        }
        return result
    }
    
    private func formatSigns(_ signs: RecoverySigns?) -> String {
        guard let signs = signs else {
            return "No recovery information available."
        }
        var result = "Good Signs:\n"
        result += signs.good.joined(separator: "\n")
        result += "\n\nRed Flags / Bad Signs:\n"
        result += signs.bad.joined(separator: "\n")
        return result
    }
    
    private func formatQuestions(_ questions: [String]) -> String {
        if questions.isEmpty {
            return "No suggested questions available."
        }
        var result = ""
        for (index, question) in questions.enumerated() {
            result += "\(index + 1). \(question)\n"
        }
        return result
    }
}


    /// Prefer model-provided actions; if empty, derive action-like lines from the simplified text.
    private func resolvedActions(output: ProcessedOutput?) -> [String] {
        let actions = output?.actions ?? []
        if !actions.isEmpty {
            return normalizeActions(actions)
        }
        let simplified = output?.simplifiedText ?? ""
        return normalizeActions(deriveActions(from: simplified))
    }

    /// Basic fallback extractor for action lines (imperatives / instructions) from plain-English text.
    private func deriveActions(from simplified: String) -> [String] {
        let lines = simplified
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Only keep lines that look like instructions rather than history/symptoms.
        let keywords = [
            "take ", "start ", "stop ", "continue ", "follow up", "book", "schedule", "call", "contact",
            "return", "go to", "seek care", "avoid", "do not", "don’t", "monitor", "check", "rest", "drink",
            "apply", "use ", "keep", "wear"
        ]

        let candidates = lines.filter { line in
            let lower = line.lowercased()
            return keywords.contains { lower.contains($0) }
        }

        // If the text uses bullets, strip bullet characters.
        let cleaned = candidates.map { line in
            line.trimmingCharacters(in: CharacterSet(charactersIn: "-*• "))
        }

        return cleaned
    }

    /// Clean up, de-dupe (case-insensitive), and cap to a reasonable number for UI.
    private func normalizeActions(_ actions: [String]) -> [String] {
        var seen = Set<String>()
        let cleaned = actions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }

        // If Gemini returned full sentences like "Here's the medical text...", drop those.
        let filtered = cleaned.filter { action in
            let lower = action.lowercased()
            return !lower.hasPrefix("here's") && !lower.hasPrefix("here is") && !lower.contains("rewritten")
        }

        return Array(filtered.prefix(12))
    }
