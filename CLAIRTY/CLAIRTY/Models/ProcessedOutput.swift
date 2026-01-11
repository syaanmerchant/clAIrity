//
//  ProcessedOutput.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Foundation

struct ProcessedOutput {
    var simplifiedText: String
    var actions: [String]
    var medications: [Medication]
    var timeline: [TimelineItem]
    var recoverySigns: RecoverySigns
    var questions: [String]
}
