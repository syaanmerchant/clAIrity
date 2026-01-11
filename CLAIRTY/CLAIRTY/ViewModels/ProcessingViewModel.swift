//
//  ProcessingViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

//
//  ProcessingViewModel.swift
//  CLAIRTY
//

import SwiftUI
import Combine
import Foundation

final class ProcessingViewModel: ObservableObject {
    @Published var processedOutput: ProcessedOutput?
    @Published var isDone = false
    @Published var errorMessage: String?

    private var input: InputData
    private var processingTask: Task<Void, Never>?

    init(input: InputData) {
        self.input = input
    }

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func parseISODate(_ s: String) -> Date? {
        Self.isoDateFormatter.date(from: s)
    }

    private func chunkText(_ text: String, maxChars: Int) -> [String] {
        guard text.count > maxChars else { return [text] }

        let paragraphs = text
            .split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r" })
            .map(String.init)

        var chunks: [String] = []
        chunks.reserveCapacity(max(2, text.count / maxChars))

        var current = ""
        current.reserveCapacity(min(maxChars, 4096))

        for p in paragraphs {
            let candidate = current.isEmpty ? p : (current + "\n" + p)
            if candidate.count <= maxChars {
                current = candidate
            } else {
                if !current.isEmpty {
                    chunks.append(current)
                    current.removeAll(keepingCapacity: true)
                }

                if p.count > maxChars {
                    var start = p.startIndex
                    while start < p.endIndex {
                        let end = p.index(start, offsetBy: maxChars, limitedBy: p.endIndex) ?? p.endIndex
                        chunks.append(String(p[start..<end]))
                        start = end
                    }
                } else {
                    current = p
                }
            }
        }

        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private func truncated(_ s: String, limit: Int) -> String {
        guard s.count > limit else { return s }
        let idx = s.index(s.startIndex, offsetBy: limit)
        return String(s[..<idx]) + "\n\n(…truncated for performance)"
    }

    func process() {
        processingTask?.cancel()
        processingTask = nil

        Task { @MainActor in
            self.errorMessage = nil
            self.isDone = false
            self.processedOutput = nil
        }

        processingTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            do {
                var text = ""

                if let image = self.input.image {
                    guard let extracted = await OCRService.extractText(from: image) else {
                        await MainActor.run {
                            self.errorMessage = "Failed to extract text from image"
                            self.isDone = true
                        }
                        return
                    }
                    text = extracted
                } else if let pdfURL = self.input.pdfURL {
                    guard let extracted = await OCRService.extractText(from: pdfURL, maxPages: 20) else {
                        await MainActor.run {
                            self.errorMessage = "Failed to extract text from PDF"
                            self.isDone = true
                        }
                        return
                    }
                    text = extracted
                } else {
                    await MainActor.run {
                        self.errorMessage = "No file selected"
                        self.isDone = true
                    }
                    return
                }

                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No text to process"
                        self.isDone = true
                    }
                    return
                }

                let chunks = self.chunkText(text, maxChars: 12_000)

                var simplifiedChunks: [String] = []
                simplifiedChunks.reserveCapacity(chunks.count)

                var allActions: [String] = []
                var allMeds: [Medication] = []
                var allTimeline: [TimelineItem] = []

                for (i, chunk) in chunks.enumerated() {
                    if Task.isCancelled { return }

                    let simplified = try await GeminiService.simplifyText(chunk)
                    simplifiedChunks.append(simplified)

                    let actions = try await GeminiService.extractActions(from: simplified)
                    allActions.append(contentsOf: actions.map { String(describing: $0) })

                    let meds = try await GeminiService.extractMeds(from: simplified)
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
                    allMeds.append(contentsOf: mappedMeds)

                    let timelineJSON = try await GeminiService.extractTimeline(originalText: chunk, simplifiedText: simplified)
                    let geminiTimeline: [TimelineItem] = timelineJSON.items.compactMap { item in
                        guard let d = self.parseISODate(item.date) else { return nil }
                        return TimelineItem(date: d, tasks: item.tasks)
                    }
                    allTimeline.append(contentsOf: geminiTimeline)

                    if i % 2 == 1 { await Task.yield() }
                }

                let combinedSimplified = simplifiedChunks.joined(separator: "\n\n")
                let simplifiedForUI = self.truncated(combinedSimplified, limit: 80_000)

                let signs = OpenAIService.extractSigns(from: simplifiedForUI)
                let questions = OpenAIService.extractQuestions(from: simplifiedForUI)

                let timeline: [TimelineItem] = allTimeline.isEmpty
                    ? OpenAIService.extractTimeline(from: simplifiedForUI)
                    : allTimeline

                let output = ProcessedOutput(
                    simplifiedText: simplifiedForUI,
                    actions: allActions,
                    medications: allMeds,
                    timeline: timeline,
                    recoverySigns: signs,
                    questions: questions
                )

                await MainActor.run {
                    self.processedOutput = output
                    self.isDone = true
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.errorMessage = "Processing failed: \(error.localizedDescription)"
                    self.isDone = true
                }
            }
        }
    }
}
