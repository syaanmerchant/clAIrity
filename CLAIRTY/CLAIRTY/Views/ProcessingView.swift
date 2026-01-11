//
//  ProcessingView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct ProcessingView: View {
    let input: InputData
    @StateObject private var viewModel: ProcessingViewModel
    @State private var showOutput = false

    @Environment(\.dismiss) private var dismiss

    init(input: InputData) {
        self.input = input
        _viewModel = StateObject(wrappedValue: ProcessingViewModel(input: input))
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing your document...")
                    .font(.headline)
                Text("This may take a moment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let error = viewModel.errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        
        .padding()
        .navigationTitle("Processing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {  // Changed from .topBarLeading
                Button("Back") {
                    dismiss()
                }
            }
        }
        .onAppear {
            showOutput = false

            Task {
                do {
                    let (_, resp) = try await URLSession.shared.data(
                        from: URL(string: "https://www.apple.com")!
                    )
                    print("🌐 Internet OK:", (resp as? HTTPURLResponse)?.statusCode ?? -1)
                } catch {
                    print("❌ Internet FAIL:", error)
                }
            }

            viewModel.process()
        }
        .onChange(of: viewModel.isDone) { _, done in
            if done {
                // If we have output, navigate; otherwise show the error on this screen
                if viewModel.processedOutput != nil {
                    showOutput = true
                }
            }
        }
        .onChange(of: showOutput) { _, active in
            if !active {
                // allow re-processing if user goes back
                showOutput = false
            }
        }
        .background(
            NavigationLink(destination: OutputView(output: viewModel.processedOutput), isActive: $showOutput) {
                EmptyView()
            }
        )
    }
    
}
