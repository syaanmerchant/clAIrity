//
//  GeminiService.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Foundation

struct GeminiAPIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
        let status: String?
        let code: Int?
    }
    let error: APIError
}

struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

struct ActionChecklistJSON: Decodable {
    let actions: [String]
}

struct GeminiMedListJSON: Decodable {
    let medications: [ExtractedMedication]
}



final class GeminiService {

    // NOTE: gemini-1.5-* model IDs may return 404; use a current Gemini model ID.
    private let model = "gemini-2.5-flash"
    
    
    struct GeminiTimelineItemJSON: Decodable {
        let date: String          // ISO "YYYY-MM-DD"
        let label: String?        // optional: "Day 1", "3–5 days"
        let tasks: [String]
    }

    struct GeminiTimelineJSON: Decodable {
        let anchorDate: String?   // ISO date if found
        let items: [GeminiTimelineItemJSON]
    }



        /// Create a patient timeline with REAL dates based on the original medical document and simplified text.
        func extractTimeline(from originalText: String, simplifiedText: String?) async throws -> GeminiTimelineJSON {
            let urlString =
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(Constants.geminiKey)"

            guard let url = URL(string: urlString) else { throw URLError(.badURL) }

            let prompt = """
    You are a medical communication assistant.

    Task:
    Create a patient timeline with REAL DATES based on the medical document.

    Rules:
    - Use dates explicitly mentioned in the document (e.g., visit date, discharge date, follow-up date).
    - Convert relative timing into dates using the anchor date from the document:
      - "in 3-5 days" => add 3 days (earliest) and mention the range in label
      - "within 48 hours" => +2 days
      - "tomorrow" => +1 day
    - ONLY include tasks that are actual patient instructions.
    - If no anchor date exists in the document, set anchorDate to null and DO NOT invent dates.
    - Create a recovery timeline and provide advice on how to recovery-- very brief

    Return STRICT JSON ONLY in this schema:
    {
      "anchorDate": "YYYY-MM-DD" or null,
      "items": [
        { "date": "YYYY-MM-DD", "label": "string or null", "tasks": ["..."] }
      ]
    }

    ORIGINAL DOCUMENT TEXT:
    \(originalText)

    SIMPLIFIED (optional):
    \(simplifiedText ?? "")
    """

            let body: [String: Any] = [
                "contents": [["parts": [["text": prompt]]]],
                "generationConfig": ["temperature": 0.1]
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

            print("Gemini (timeline) HTTP status:", http.statusCode)

            if !(200...299).contains(http.statusCode) {
                if let apiErr = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                    throw NSError(
                        domain: "GeminiAPI",
                        code: apiErr.error.code ?? http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(apiErr.error.message)"]
                    )
                }
                let raw = String(data: data, encoding: .utf8) ?? "<no body>"
                throw NSError(
                    domain: "GeminiAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(raw)"]
                )
            }

            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let output = decoded.candidates.first?.content.parts.compactMap { $0.text }.joined() ?? ""
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let start = trimmed.firstIndex(of: "{"),
                  let end = trimmed.lastIndex(of: "}") else {
                throw NSError(
                    domain: "GeminiAPI",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Timeline JSON not found in response"]
                )
            }

            let jsonSlice = String(trimmed[start...end])
            return try JSONDecoder().decode(GeminiTimelineJSON.self, from: Data(jsonSlice.utf8))
        }

        /// Convenience static wrapper for ViewModels
        

    static func extractTimeline(originalText: String, simplifiedText: String?) async throws -> GeminiTimelineJSON {
        let service = GeminiService()
        return try await service.extractTimeline(from: originalText, simplifiedText: simplifiedText)
    }

    
    func simplifyMedicalText(_ text: String) async throws -> String {

        let urlString =
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(Constants.geminiKey)"
        print("Gemini URL:", urlString)
        print("Gemini key length:", Constants.geminiKey.count)

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let prompt = """
You are a medical communication assistant.

Task:
Rewrite the following medical text into SIMPLE, PLAIN ENGLISH that a normal person can understand.

Rules:
- Do NOT add new medical advice
- Do NOT change medication doses or timing
- Explain abbreviations (e.g., PRN, BID, SOB)
- Use short sentences
- Use bullet points if helpful with no headers and keep it cohesive 
- Keep items short and actionable.
- Keep meaning exactly the same and ignore section headers

Medical text:
\(text)
"""

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            print("Gemini HTTP status:", http.statusCode)

            // If Gemini returns an error (e.g., 404 model not found), surface the message instead of decoding as GeminiResponse.
            if !(200...299).contains(http.statusCode) {
                if let apiErr = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                    throw NSError(
                        domain: "GeminiAPI",
                        code: apiErr.error.code ?? http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(apiErr.error.message)"]
                    )
                }
                let raw = String(data: data, encoding: .utf8) ?? "<no body>"
                throw NSError(
                    domain: "GeminiAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(raw)"]
                )
            }

            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)

            let output =
                decoded.candidates
                    .first?
                    .content
                    .parts
                    .compactMap { $0.text }
                    .joined() ?? ""

            return output.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            print("❌ URLSession error:", error)
            throw error
        }
    }

    /// Extract ONLY explicit patient instructions (what the person needs to DO) from simplified plain-English text.
    /// Ignores history/symptoms/section headers/provider names. Returns short imperative items.
    func extractActionChecklist(from simpleEnglish: String) async throws -> [String] {
        let urlString =
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(Constants.geminiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let prompt = """
You are a medical communication assistant.

Task: From the SIMPLE ENGLISH text below, extract ONLY explicit patient instructions.

IMPORTANT:
- Ignore patient history, symptoms, diagnoses, provider names, and section headers.
- Only include actions the patient is instructed to do AFTER the visit (medications, follow-up, restrictions, monitoring, return precautions).
- Do NOT add new medical advice.
- Do NOT invent medications, doses, or timelines.
- Keep items short and actionable (start with a verb).
- If there are NO clear instructions, return an empty list.

Return STRICT JSON ONLY in this exact schema:
{"actions":["..."]}

SIMPLE ENGLISH:
\(simpleEnglish)
"""

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            print("Gemini (actions) HTTP status:", http.statusCode)

            if !(200...299).contains(http.statusCode) {
                if let apiErr = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                    throw NSError(
                        domain: "GeminiAPI",
                        code: apiErr.error.code ?? http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(apiErr.error.message)"]
                    )
                }
                let raw = String(data: data, encoding: .utf8) ?? "<no body>"
                throw NSError(
                    domain: "GeminiAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(raw)"]
                )
            }

            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let output = decoded.candidates
                .first?
                .content
                .parts
                .compactMap { $0.text }
                .joined() ?? ""

            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            // Gemini may wrap JSON in extra text; decode the substring between first '{' and last '}'
            guard let start = trimmed.firstIndex(of: "{"),
                  let end = trimmed.lastIndex(of: "}") else {
                return []
            }

            let jsonSlice = String(trimmed[start...end])
            let actions = try JSONDecoder().decode(ActionChecklistJSON.self, from: Data(jsonSlice.utf8)).actions

            // Clean + de-dupe case-insensitively while preserving first occurrence
            var seen = Set<String>()
            let cleaned = actions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .filter { seen.insert($0.lowercased()).inserted }

            return cleaned

        } catch {
            print("❌ Gemini (actions) URLSession error:", error)
            throw error
        }
    }

    /// Extract medications (name + dose/frequency/etc.) from simplified plain-English text.
    /// Returns only meds explicitly mentioned; does not invent missing fields.
    func extractMedications(from simpleEnglish: String) async throws -> [ExtractedMedication] {
        let urlString =
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(Constants.geminiKey)"

        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let prompt = """
You are a medical communication assistant.

Task: From the SIMPLE ENGLISH text below, extract ONLY medications the patient should take/use.

Rules:
- Do NOT add new meds.
- Do NOT invent doses/timing.
- If a field is not stated, use null.
- Return STRICT JSON ONLY in this schema:
{
  "medications": [
    {
      "name": "ibuprofen",
      "strength": "400 mg",
      "form": "tablet",
      "route": "by mouth",
      "frequency": "every 6 hours as needed",
      "duration": null,
      "instructions": "for pain"
    }
  ]
}

SIMPLE ENGLISH:
\(simpleEnglish)
"""

        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]],
            "generationConfig": [
                "temperature": 0.1
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

            print("Gemini (meds) HTTP status:", http.statusCode)

            if !(200...299).contains(http.statusCode) {
                if let apiErr = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                    throw NSError(
                        domain: "GeminiAPI",
                        code: apiErr.error.code ?? http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(apiErr.error.message)"]
                    )
                }
                let raw = String(data: data, encoding: .utf8) ?? "<no body>"
                throw NSError(
                    domain: "GeminiAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(raw)"]
                )
            }

            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let output = decoded.candidates
                .first?
                .content
                .parts
                .compactMap { $0.text }
                .joined() ?? ""

            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let start = trimmed.firstIndex(of: "{"),
                  let end = trimmed.lastIndex(of: "}") else {
                return []
            }

            let jsonSlice = String(trimmed[start...end])
            let meds = try JSONDecoder().decode(GeminiMedListJSON.self, from: Data(jsonSlice.utf8)).medications

            // Clean + de-dupe by name+strength+freq (case-insensitive), preserving first occurrence
            var seen = Set<String>()
            let cleaned = meds.filter { med in
                let key = [med.name, med.strength ?? "", med.frequency ?? ""]
                    .joined(separator: "|")
                    .lowercased()
                return seen.insert(key).inserted
            }

            return cleaned

        } catch {
            print("❌ Gemini (meds) URLSession error:", error)
            throw error
        }
    }

    // Convenience static wrapper for ViewModels
    static func simplifyText(_ text: String) async throws -> String {
        let service = GeminiService()
        return try await service.simplifyMedicalText(text)
    }

    // Convenience static wrapper for ViewModels
    static func extractActions(from simpleEnglish: String) async throws -> [String] {
        let service = GeminiService()
        return try await service.extractActionChecklist(from: simpleEnglish)
    }

    // Convenience static wrapper for ViewModels
    static func extractMeds(from simpleEnglish: String) async throws -> [ExtractedMedication] {
        let service = GeminiService()
        return try await service.extractMedications(from: simpleEnglish)
    }
}

