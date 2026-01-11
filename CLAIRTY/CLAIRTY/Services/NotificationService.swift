//
//  NotificationService.swift
//  CLAIRTY
//
//  Created by Syaan Merchant on 2026-01-10.
//
import UserNotifications
import Foundation

class NotificationService {
    static func scheduleReminders(_ reminders: [Reminder]) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification Authorization Error: \(error)")
                return
            }
            
            if granted {
                for reminder in reminders {
                    let content = UNMutableNotificationContent()
                    content.title = "Health Reminder"
                    content.body = reminder.message
                    content.sound = .default
                    
                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: reminder.date
                    )
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: trigger
                    )
                    
                    center.add(request) { addError in
                        if let addError = addError {
                            print("Error scheduling notification: \(addError)")
                        }
                    }
                }
            }
        }
    }
}
