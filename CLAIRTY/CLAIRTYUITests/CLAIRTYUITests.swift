//
//  CLAIRTYUITests.swift
//  CLAIRTYUITests
//
//  Created by Syaan Merchant on 2026-01-10.
//


import XCTest

final class CLAIRTYUITests: XCTestCase {

    func testInputToOutputFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to input
        app.buttons["Get Started"].tap()
        
        // Enter text
        let textField = app.textFields["Paste medical text here"]
        textField.tap()
        textField.typeText("Take medication daily.")
        
        // Process
        app.buttons["Process"].tap()
        
        // Check output
        XCTAssert(app.staticTexts["Understanding"].exists)
    }
}

