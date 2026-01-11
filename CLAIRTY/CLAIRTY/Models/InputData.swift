//
//  InputData.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

//
//  InputData.swift
//  CLAIRTY
//

import Foundation
import UIKit

struct InputData {
    /// Exactly one of these should be non-nil.
    var image: UIImage?
    var pdfURL: URL?

    init(image: UIImage) {
        self.image = image
        self.pdfURL = nil
    }

    init(pdfURL: URL) {
        self.image = nil
        self.pdfURL = pdfURL
    }
}
