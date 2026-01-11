//
//  InputView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//


import SwiftUI
import PhotosUI

struct InputView: View {
    @StateObject private var viewModel = InputViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showProcessing = false

    var body: some View {
        Form {
            Section(header: Text("Select What Happened")) {
                Picker("Type", selection: $viewModel.inputData.diagnosis) {
                    Text("GP Visit").tag("GP Visit" as String?)
                    Text("ER Discharge").tag("ER Discharge" as String?)
                    Text("Specialist Consult").tag("Specialist Consult" as String?)
                    //Text("Insurance Letter").tag("Insurance Letter" as String?)
                    //Text("Other Document").tag("Other Document" as String?)
                }
            }
            
            Section(header: Text("Input Text")) {
                TextEditor(text: Binding(
                    get: { viewModel.inputData.text ?? "" },
                    set: { viewModel.inputData.text = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
            
            Section(header: Text("Upload Document")) {
                PhotosPicker("Select Image from Library", selection: $selectedItem, matching: .images)
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                }
                
                if viewModel.inputData.image != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Image selected")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Optional Information")) {
                TextField("Symptoms (comma-separated)", text: Binding(
                    get: { viewModel.inputData.symptoms?.joined(separator: ", ") ?? "" },
                    set: {
                        let value = $0.trimmingCharacters(in: .whitespaces)
                        viewModel.inputData.symptoms = value.isEmpty ? nil : value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    }
                ))
                
                TextField("Current Medications (comma-separated)", text: Binding(
                    get: { viewModel.inputData.medications?.joined(separator: ", ") ?? "" },
                    set: {
                        let value = $0.trimmingCharacters(in: .whitespaces)
                        viewModel.inputData.medications = value.isEmpty ? nil : value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    }
                ))
            }
            
            Section {
                Button(action: {
                    showProcessing = true
                }) {
                    HStack {
                        Spacer()
                        Text("Process Document")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(viewModel.inputData.text == nil && viewModel.inputData.image == nil)
            }
        }
        .navigationTitle("Input")
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $viewModel.inputData.image)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.inputData.image = uiImage
                }
            }
        }
        .background(
            NavigationLink(destination: ProcessingView(input: viewModel.inputData), isActive: $showProcessing) {
                EmptyView()
            }
        )
    }
}

// Simple ImagePicker for camera
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
}
