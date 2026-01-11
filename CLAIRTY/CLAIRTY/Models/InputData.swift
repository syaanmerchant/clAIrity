//
//  InputData.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Foundation
import UIKit  // Added for UIImage

struct InputData {
    var text: String?
    var image: UIImage?  // Now works with UIKit import
    var diagnosis: String?
    var symptoms: [String]?
    var medications: [String]?
}
