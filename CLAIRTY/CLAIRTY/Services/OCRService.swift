//
//  OCRService.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import Vision
import UIKit

class OCRService {
    static func extractText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error)")
                return
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return nil
            }
            return observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
        } catch {
            print("OCR Handler Error: \(error)")
            return nil
        }
    }
}
