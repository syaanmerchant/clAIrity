//
//  InputViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

//
//  InputViewModel.swift
//  CLAIRTY
//

import Foundation
import UIKit

final class InputViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var selectedPDFURL: URL? = nil

    var inputData: InputData? {
        if let img = selectedImage { return InputData(image: img) }
        if let url = selectedPDFURL { return InputData(pdfURL: url) }
        return nil
    }

    func setImage(_ image: UIImage?) {
        selectedImage = image
        if image != nil { selectedPDFURL = nil }
    }

    func setPDFURL(_ url: URL?) {
        selectedPDFURL = url
        if url != nil { selectedImage = nil }
    }

    func clearSelection() {
        selectedImage = nil
        selectedPDFURL = nil
    }
}
