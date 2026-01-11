//
//  InputViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI
import Combine

class InputViewModel: ObservableObject {
    @Published var inputData = InputData()
    @Published var shouldNavigateToProcessing = false

    func processInput() {
        // Basic validation
        if inputData.text != nil || inputData.image != nil {
            shouldNavigateToProcessing = true
        }
    }
}
