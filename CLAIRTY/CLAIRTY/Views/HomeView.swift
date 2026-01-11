//
//  HomeView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct HomeView: View {
    @State private var showInput = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Title
            Text("CLAIRTY")
                .font(.largeTitle)
                .bold()
                .tracking(5)
            
            // Tagline
            Text("Turn medical language into plain English")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Start Button
            Button(action: {
                showInput = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Disclaimer
            Text("For informational purposes only. Consult a healthcare professional for medical advice.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
        }
        .background(
            NavigationLink(destination: InputView(), isActive: $showInput) {
                EmptyView()
            }
        )
    }
}
