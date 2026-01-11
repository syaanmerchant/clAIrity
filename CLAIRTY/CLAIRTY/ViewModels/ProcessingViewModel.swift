//
//  ProcessingViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI
import Combine

class ProcessingViewModel: ObservableObject {
    @Published var processedOutput: ProcessedOutput?
    @Published var isDone = false
    @Published var errorMessage: String?
    private var input: InputData

    init(input: InputData) {
        self.input = input
    }

    private func parseISODate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    func process() {
        Task {
            do {
                // OCR if image
                var text = input.text ?? ""
                if let image = input.image {
                    if let extractedText = await OCRService.extractText(from: image) {
                        text = extractedText
                    } else {
                        await MainActor.run {
                            self.errorMessage = "Failed to extract text from image"
                            self.isDone = true
                        }
                        return
                    }
                }

                guard !text.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No text to process"
                        self.isDone = true
                    }
                    return
                }

                // Simplify with Gemini, then extract into cards
                let simplified = try await GeminiService.simplifyText(text)
                let actions = try await GeminiService.extractActions(from: simplified)
                let meds = try await GeminiService.extractMeds(from: simplified)

                // Map Gemini-extracted meds into your app's Medication model
                let mappedMeds: [Medication] = meds.map { m in
                    let doseBits = [m.strength, m.frequency].compactMap { $0 }.filter { !$0.isEmpty }
                    let dosage = doseBits.isEmpty ? "" : doseBits.joined(separator: " • ")

                    var notesParts: [String] = []
                    if let form = m.form, !form.isEmpty { notesParts.append("Form: \(form)") }
                    if let route = m.route, !route.isEmpty { notesParts.append("Route: \(route)") }
                    if let instr = m.instructions, !instr.isEmpty { notesParts.append(instr) }
                    let notes = notesParts.joined(separator: " • ")

                    return Medication(
                        name: m.name,
                        dosage: dosage,
                        duration: m.duration ?? "",
                        notes: notes
                    )
                }

                // Build a date-accurate timeline from the ORIGINAL document text (and simplified text)
                let geminiTimelineJSON = try await GeminiService.extractTimeline(originalText: text, simplifiedText: simplified)
                let geminiTimeline: [TimelineItem] = geminiTimelineJSON.items.compactMap { item in
                    guard let d = parseISODate(item.date) else { return nil }
                    return TimelineItem(date: d, tasks: item.tasks)
                }
                // Prefer Gemini date-accurate timeline; fall back to existing extractor if empty
                let timeline = geminiTimeline.isEmpty ? OpenAIService.extractTimeline(from: simplified) : geminiTimeline
                let signs = OpenAIService.extractSigns(from: simplified)
                let questions = OpenAIService.extractQuestions(from: simplified)

                let output = ProcessedOutput(
                    simplifiedText: simplified,
                    actions: actions,
                    medications: mappedMeds,
                    timeline: timeline,
                    recoverySigns: signs,
                    questions: questions
                )

                await MainActor.run {
                    self.processedOutput = output
                    self.isDone = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Processing failed: \(error.localizedDescription)"
                    self.isDone = true
                }
            }
        }
    }
}

