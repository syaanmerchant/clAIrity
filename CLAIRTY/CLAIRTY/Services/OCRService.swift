//
//  OCRService.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

//
//  OCRService.swift
//  CLAIRTY
//

import Foundation
import UIKit
import Vision
import PDFKit

enum OCRService {

    // MARK: - Image OCR

    static func extractText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines: [String] = observations.compactMap { obs in
                    obs.topCandidates(1).first?.string
                }

                let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: text.isEmpty ? nil : text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - PDF OCR (render pages -> OCR)

    static func extractText(from pdfURL: URL, maxPages: Int = 20) async -> String? {
        guard let doc = PDFDocument(url: pdfURL) else { return nil }

        let pageCount = min(doc.pageCount, maxPages)
        var results: [String] = []
        results.reserveCapacity(pageCount)

        for i in 0..<pageCount {
            guard let page = doc.page(at: i) else { continue }
            let img = render(page: page, scale: 2.0)

            if let pageText = await extractText(from: img) {
                results.append(pageText)
            }
            await Task.yield()
        }

        let joined = results.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    private static func render(page: PDFPage, scale: CGFloat) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))

            ctx.cgContext.saveGState()
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
    }
}
