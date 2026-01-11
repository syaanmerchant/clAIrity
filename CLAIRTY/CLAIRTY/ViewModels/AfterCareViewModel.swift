//
//  AfterCareViewModel.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//

import SwiftUI
import UserNotifications

class AfterCareViewModel: ObservableObject {
    @Published var plan: AfterCarePlan?
    private var output: ProcessedOutput?

    init(output: ProcessedOutput?) {
        self.output = output
    }

    func generatePlan() {
        guard let output = output else { return }
        
        // Generate daily plans based on actions
        let dailyPlans = [
            DailyPlan(day: 1, tasks: Array(output.actions.prefix(3))),
            DailyPlan(day: 2, tasks: ["Continue medications", "Rest and hydrate"]),
            DailyPlan(day: 3, tasks: ["Check symptoms", "Light activity if feeling better"]),
            DailyPlan(day: 7, tasks: ["Assess full recovery", "Complete any remaining medications"])
        ]
        
        // Generate triggers from red flags
        let triggers = output.recoverySigns.bad.map { badSign in
            Trigger(condition: badSign, action: "Contact your healthcare provider immediately or go to the ER")
        }
        
        // Generate reminders for medications
        var reminders: [Reminder] = []
        for med in output.medications {
            let reminderMessage = "Take \(med.name): \(med.dosage) - \(med.notes)"
            let reminder = Reminder(date: Date().addingTimeInterval(3600), message: reminderMessage)
            reminders.append(reminder)
        }
        
        // Add a general follow-up reminder
        let followUpReminder = Reminder(date: Date().addingTimeInterval(86400 * 3), message: "Check your symptoms and progress")
        reminders.append(followUpReminder)
        
        plan = AfterCarePlan(dailyPlans: Array(dailyPlans), triggers: triggers, reminders: reminders)
        
        // Schedule notifications
        NotificationService.scheduleReminders(reminders)
    }
}
