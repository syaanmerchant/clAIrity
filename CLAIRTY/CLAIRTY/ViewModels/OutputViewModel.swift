//
//  OutputViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

class OutputViewModel: ObservableObject {
    @Published var output: ProcessedOutput?

    init(output: ProcessedOutput?) {
        self.output = output
    }
}
