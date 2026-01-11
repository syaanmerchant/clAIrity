//
//  OpenAIService.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Foundation

class OpenAIService {
    // Note: OpenAIKit is not used directly here to avoid compilation issues
    // For production, integrate OpenAIKit via SPM: https://github.com/dylanshine/openai-kit
    
    static func simplifyText(_ text: String) async -> String {
        // This is a simplified version without OpenAI dependency
        // For full functionality, add OpenAIKit and use GPT for processing
        
        let sentences = text.components(separatedBy: ". ")
        var simplified = ""
        
        for sentence in sentences {
            let lower = sentence.lowercased()
            if lower.contains("diagnosis") || lower.contains("diagnosed") {
                simplified += "You have been diagnosed with: " + sentence + ". "
            } else if lower.contains("prescribe") || lower.contains("prescription") {
                simplified += "Medication prescribed: " + sentence + ". "
            } else if lower.contains("follow-up") || lower.contains("follow up") {
                simplified += "You need to return for a follow-up: " + sentence + ". "
            } else if lower.contains("discharge") {
                simplified += "Instructions for leaving: " + sentence + ". "
            } else {
                simplified += sentence + ". "
            }
        }
        
        return simplified.isEmpty ? text : simplified
    }

    static func extractMedications(from text: String) -> [Medication] {
        var medications: [Medication] = []
        
        let patterns = [
            "take (.+?) of (.+?)(?:,|\\.|\\$)",
            "prescribed (.+?) (.+?) daily",
            "dosage: (.+?) of (.+?)"
        ]
        
        _ = text.lowercased()
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..., in: text)
            if let matches = regex?.matches(in: text, range: range) {
                for match in matches {
                    if match.numberOfRanges >= 3 {
                        let dosage = (text as NSString).substring(with: match.range(at: 1))
                        let name = (text as NSString).substring(with: match.range(at: 2))
                        let med = Medication(
                            name: name.trimmingCharacters(in: .whitespaces),
                            dosage: dosage.trimmingCharacters(in: .whitespaces),
                            duration: "As prescribed",
                            notes: "Take with food if stomach upset occurs"
                        )
                        medications.append(med)
                    }
                }
            }
        }
        
        // If no medications found, return empty array
        return medications
    }

    static func extractActions(from text: String) -> [String] {
        var actions: [String] = []
        
        let keywords = ["take", "do", "follow", "avoid", "rest", "apply", "use", "complete"]
        let sentences = text.components(separatedBy: ". ")
        
        for sentence in sentences {
            let lower = sentence.lowercased()
            for keyword in keywords {
                if lower.contains(keyword) && sentence.count > 10 {
                    let trimmed = sentence.trimmingCharacters(in: .whitespaces)
                    if !actions.contains(trimmed) {
                        actions.append(trimmed)
                    }
                    break
                }
            }
        }
        
        return actions.isEmpty ? ["Follow all instructions provided by your healthcare provider"] : actions
    }

    static func extractTimeline(from text: String) -> [TimelineItem] {
        let today = Date()
        
        return [
            TimelineItem(date: today, tasks: ["Review discharge instructions", "Take prescribed medications"]),
            TimelineItem(date: Calendar.current.date(byAdding: .day, value: 1, to: today)!, tasks: ["Rest and recover", "Monitor symptoms"]),
            TimelineItem(date: Calendar.current.date(byAdding: .day, value: 3, to: today)!, tasks: ["Check if symptoms are improving", "Schedule follow-up if needed"]),
            TimelineItem(date: Calendar.current.date(byAdding: .day, value: 7, to: today)!, tasks: ["Assess full recovery", "Complete any remaining medications"])
        ]
    }

    static func extractSigns(from text: String) -> RecoverySigns {
        let lowerText = text.lowercased()
        
        let goodSigns = [
            "Feeling gradually better",
            "Reducing pain levels",
            "Improved energy",
            "Better appetite"
        ]
        
        var badSigns = [
            "Fever over 101°F (38.3°C)",
            "Increased pain or swelling",
            "Difficulty breathing",
            "Unusual bleeding"
        ]
        
        // Check text for specific mentions
        if lowerText.contains("fever") || lowerText.contains("temperature") {
            badSigns.append("Monitor for fever")
        }
        if lowerText.contains("pain") {
            badSigns.append("Watch for increased pain")
        }
        if lowerText.contains("bleed") || lowerText.contains("bleeding") {
            badSigns.append("Watch for unusual bleeding")
        }
        if lowerText.contains("infection") {
            badSigns.append("Signs of infection (redness, warmth, pus)")
        }
        
        return RecoverySigns(good: goodSigns, bad: badSigns)
    }

    static func extractQuestions(from text: String) -> [String] {
        return [
            "What should I do if I miss a dose of my medication?",
            "When should I follow up with my healthcare provider?",
            "What side effects should I watch for?",
            "Are there any activity restrictions I should follow?",
            "What symptoms should prompt me to seek immediate care?",
            "How should I care for my incision/wound (if applicable)?",
            "When can I return to normal activities or work?"
        ]
    }
}
