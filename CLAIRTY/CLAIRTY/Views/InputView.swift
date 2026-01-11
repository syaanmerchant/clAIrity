//
//  InputView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//


//
//  InputView.swift
//  CLAIRTY
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct InputView: View {
    @StateObject private var viewModel = InputViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPickError = false
    @State private var pickErrorMessage = ""

    @State private var showCamera = false
    @State private var showProcessing = false
    @State private var showPDFImporter = false
    @State private var showImageImporter = false

    private func copyToTempIfNeeded(url: URL) -> URL? {
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }

        let fm = FileManager.default
        let dest = fm.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)

        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: url, to: dest)
            return dest
        } catch {
            return nil
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Upload")) {
                PhotosPicker("Choose Photo (Photos)", selection: $selectedItem, matching: .images)

                Button {
                    showImageImporter = true
                } label: {
                    HStack {
                        Image(systemName: "doc")
                        Text("Choose Image (Files)")
                    }
                }

                Button {
                    showPDFImporter = true
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("Choose PDF (Files)")
                    }
                }

                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                }

                if viewModel.selectedImage != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Image selected").foregroundColor(.secondary)
                    }
                } else if viewModel.selectedPDFURL != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("PDF selected").foregroundColor(.secondary)
                    }
                }

                if viewModel.selectedImage != nil || viewModel.selectedPDFURL != nil {
                    Button(role: .destructive) {
                        viewModel.clearSelection()
                        selectedItem = nil
                    } label: {
                        Text("Clear selection")
                    }
                }
            }

            Section {
                Button {
                    showProcessing = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Process Document").font(.headline)
                        Spacer()
                    }
                }
                .disabled(viewModel.inputData == nil)
            }
        }
        .navigationTitle("Input")

        // Camera
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: Binding(
                get: { viewModel.selectedImage },
                set: { viewModel.setImage($0) }
            ))
        }

        // PhotosPicker -> UIImage
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.setImage(uiImage)
                }
            }
        }
        .alert("Can’t Import", isPresented: $showPickError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(pickErrorMessage)
        }

        // PDF picker
        .fileImporter(
            isPresented: $showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.setPDFURL(copyToTempIfNeeded(url: url) ?? url)
            case .failure:
                break
            }
        }

        // Image from Files picker
        .fileImporter(
            isPresented: $showImageImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let usable = copyToTempIfNeeded(url: url) ?? url

                // ✅ If a PDF somehow shows up here, reject it and tell the user what to do.
                if let type = try? usable.resourceValues(forKeys: [.contentTypeKey]).contentType,
                   type.conforms(to: .pdf) {
                    pickErrorMessage = "That’s a PDF. Use “Choose PDF (Files)” instead."
                    showPickError = true
                    return
                }

                if let data = try? Data(contentsOf: usable),
                   let img = UIImage(data: data) {
                    viewModel.setImage(img)
                } else {
                    pickErrorMessage = "Couldn’t load that image file."
                    showPickError = true
                }

            case .failure(let error):
                pickErrorMessage = "File import failed: \(error.localizedDescription)"
                showPickError = true
            }
        }
        // Navigate to processing
        .background(
            NavigationLink(
                destination: Group {
                    if let input = viewModel.inputData {
                        ProcessingView(input: input)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $showProcessing
            ) { EmptyView() }
        )
    }
}

// Camera picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
}
