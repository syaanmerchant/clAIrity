//
//  CLAIRTYTests.swift
//  CLAIRTYTests
//
//  Created by Syaan Merchant on 2026-01-10.
//

import XCTest
@testable import CLAIRTY

class CLAIRTYTests: XCTestCase {

    func testExtractMedications() {
        let text = "Take 500mg of aspirin daily with food."
        let meds = OpenAIService.extractMedications(from: text)
        XCTAssertEqual(meds.count, 1)
        XCTAssertEqual(meds.first?.name, "aspirin")
        XCTAssertEqual(meds.first?.dosage, "500mg")
    }

    func testSimplifyText() async {
        // Note: This requires a valid API key; mock or skip in CI
        let text = "You have hypertension."
        let simplified = await OpenAIService.simplifyText(text)
        XCTAssertFalse(simplified.isEmpty)
    }

    func testDateExtension() {
        let date = Date()
        let future = date.adding(days: 1)
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: date, to: future).day, 1)
    }
}
