//
//  AfterCareView.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI

struct AfterCareView: View {
    let output: ProcessedOutput?
    @StateObject private var viewModel: AfterCareViewModel

    init(output: ProcessedOutput?) {
        self.output = output
        self._viewModel = StateObject(wrappedValue: AfterCareViewModel(output: output))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("After-Care Plan")
                        .font(.title)
                        .bold()
                    Text("Your personalized recovery roadmap")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Daily Plans Section
                VStack(alignment: .leading, spacing: 15) {
                    SectionHeader(title: "Daily Plans", icon: "calendar.badge.clock")
                    
                    ForEach(viewModel.plan?.dailyPlans ?? [], id: \.day) { plan in
                        DailyPlanCard(plan: plan)
                    }
                }
                .padding(.horizontal)
                
                // Triggers Section
                VStack(alignment: .leading, spacing: 15) {
                    SectionHeader(title: "Safety Triggers", icon: "exclamationmark.triangle.fill")
                    
                    ForEach(viewModel.plan?.triggers ?? [], id: \.condition) { trigger in
                        TriggerCard(trigger: trigger)
                    }
                }
                .padding(.horizontal)
                
                // Reminders Section
                VStack(alignment: .leading, spacing: 15) {
                    SectionHeader(title: "Reminders", icon: "bell.fill")
                    
                    ForEach(viewModel.plan?.reminders ?? [], id: \.message) { reminder in
                        ReminderCard(reminder: reminder)
                    }
                }
                .padding(.horizontal)
                
                // Back to Results Button
                Button(action: {
                    // This will automatically pop back due to NavigationLink
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Results")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Disclaimer
                VStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("This plan is generated from your documents and is for informational purposes only. Always follow your healthcare provider's specific instructions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("After-Care")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.generatePlan()
        }
    }
}

// Helper Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.bottom, 5)
    }
}

struct DailyPlanCard: View {
    let plan: DailyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Day \(plan.day)")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(dayDescription(plan.day))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(plan.tasks, id: \.self) { task in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(task)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func dayDescription(_ day: Int) -> String {
        switch day {
        case 1: return "Today"
        case 2: return "Tomorrow"
        default: return "In \(day) days"
        }
    }
}

struct TriggerCard: View {
    let trigger: Trigger
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("If this happens:")
                    .font(.subheadline)
                    .bold()
            }
            Text(trigger.condition)
                .font(.body)
                .foregroundColor(.primary)
            
            Divider()
            
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                Text("Then do this:")
                    .font(.subheadline)
                    .bold()
            }
            Text(trigger.action)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(reminder.message)
                    .font(.subheadline)
                    .bold()
                Text(DateFormatter.localizedString(from: reminder.date, dateStyle: .short, timeStyle: .short))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}
