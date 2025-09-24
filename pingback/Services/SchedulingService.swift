import Foundation

/// Service for handling follow-up scheduling with quiet hours support
@MainActor
class SchedulingService: ObservableObject {
    static let shared = SchedulingService()
    
    private init() {}
    
    // MARK: - Quiet Hours Configuration
    
    struct QuietHours {
        let startHour: Int // 22 (10 PM)
        let endHour: Int   // 7 (7 AM)
        
        static let `default` = QuietHours(startHour: 22, endHour: 7)
    }
    
    private let quietHours = QuietHours.default
    private let workingHours = (start: 9, end: 17) // 9 AM - 5 PM
    private let defaultEveningHour = 18 // 6 PM
    private let defaultMorningHour = 9  // 9 AM
    
    // MARK: - Smart Scheduling
    
    /// Calculate the next appropriate due time based on current time and quiet hours
    /// - Parameter now: Current date/time
    /// - Returns: Next appropriate due date
    func calculateNextDueTime(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // If within working hours (9 AM - 5 PM), schedule for today 6 PM
        if currentHour >= workingHours.start && currentHour < workingHours.end {
            if let todayEvening = calendar.date(bySettingHour: defaultEveningHour, minute: 0, second: 0, of: now) {
                return todayEvening
            }
        }
        
        // If after 5 PM but before quiet hours (10 PM), schedule for today 6 PM if not passed
        if currentHour >= workingHours.end && currentHour < quietHours.startHour {
            if let todayEvening = calendar.date(bySettingHour: defaultEveningHour, minute: 0, second: 0, of: now),
               todayEvening > now {
                return todayEvening
            }
        }
        
        // Otherwise, schedule for tomorrow 9 AM
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return calendar.date(bySettingHour: defaultMorningHour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
    
    /// Get quick time options for share extension
    /// - Parameter now: Current date/time
    /// - Returns: Array of quick time options
    func getQuickTimeOptions(from now: Date = Date()) -> [QuickTimeOption] {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        var options: [QuickTimeOption] = []
        
        // Today 6 PM (if it's before 6 PM and not in quiet hours)
        if currentHour < defaultEveningHour {
            if let todayEvening = calendar.date(bySettingHour: defaultEveningHour, minute: 0, second: 0, of: now) {
                let isDefault = currentHour >= workingHours.start && currentHour < workingHours.end
                options.append(QuickTimeOption(
                    title: "Today 6 PM",
                    subtitle: "This evening",
                    date: todayEvening,
                    isDefault: isDefault
                ))
            }
        }
        
        // Tomorrow 9 AM (always available and default if after 5 PM)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        if let tomorrowMorning = calendar.date(bySettingHour: defaultMorningHour, minute: 0, second: 0, of: tomorrow) {
            let isDefault = currentHour >= workingHours.end || currentHour < workingHours.start
            options.append(QuickTimeOption(
                title: "Tomorrow 9 AM",
                subtitle: "Tomorrow morning",
                date: tomorrowMorning,
                isDefault: isDefault
            ))
        }
        
        // Pick custom time
        options.append(QuickTimeOption(
            title: "Pick…",
            subtitle: "Custom time",
            date: calculateNextDueTime(from: now),
            isDefault: false
        ))
        
        return options
    }
    
    /// Validate and adjust a date to respect quiet hours
    /// - Parameter date: Proposed date
    /// - Returns: Adjusted date that respects quiet hours
    func adjustForQuietHours(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // If the time falls within quiet hours (10 PM - 7 AM), move to next 9 AM
        if isInQuietHours(hour: hour) {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return calendar.date(bySettingHour: defaultMorningHour, minute: 0, second: 0, of: nextDay) ?? date
        }
        
        return date
    }
    
    /// Check if an hour is within quiet hours
    /// - Parameter hour: Hour to check (0-23)
    /// - Returns: True if within quiet hours
    private func isInQuietHours(hour: Int) -> Bool {
        // Quiet hours: 22:00 (10 PM) to 07:00 (7 AM)
        return hour >= quietHours.startHour || hour < quietHours.endHour
    }
    
    // MARK: - Snooze Options
    
    /// Get snooze options based on current time
    /// - Parameter now: Current date/time
    /// - Returns: Array of snooze options
    func getSnoozeOptions(from now: Date = Date()) -> [SnoozeOption] {
        let calendar = Calendar.current
        
        var options: [SnoozeOption] = []
        
        // +1 hour (always available)
        let oneHourLater = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        options.append(SnoozeOption(
            title: "+1 hour",
            subtitle: oneHourLater.formatted(date: .omitted, time: .shortened),
            interval: 3600 // 1 hour in seconds
        ))
        
        // Tonight 6 PM (if before 6 PM)
        let currentHour = calendar.component(.hour, from: now)
        if currentHour < defaultEveningHour {
            if let todayEvening = calendar.date(bySettingHour: defaultEveningHour, minute: 0, second: 0, of: now) {
                let interval = todayEvening.timeIntervalSince(now)
                options.append(SnoozeOption(
                    title: "Tonight 6 PM",
                    subtitle: "This evening",
                    interval: interval
                ))
            }
        }
        
        // Tomorrow 9 AM
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        if let tomorrowMorning = calendar.date(bySettingHour: defaultMorningHour, minute: 0, second: 0, of: tomorrow) {
            let interval = tomorrowMorning.timeIntervalSince(now)
            options.append(SnoozeOption(
                title: "Tomorrow 9 AM",
                subtitle: "Tomorrow morning",
                interval: interval
            ))
        }
        
        return options
    }
    
    // MARK: - Cadence Scheduling
    
    /// Calculate next cadence date
    /// - Parameters:
    ///   - from: Starting date
    ///   - cadence: Cadence type
    /// - Returns: Next due date based on cadence
    func calculateNextCadenceDate(from date: Date, cadence: Cadence) -> Date {
        let calendar = Calendar.current
        
        let nextDate: Date
        switch cadence {
        case .every7Days:
            nextDate = calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .every30Days:
            nextDate = calendar.date(byAdding: .day, value: 30, to: date) ?? date
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .none:
            return date
        }
        
        // Adjust for quiet hours
        return adjustForQuietHours(nextDate)
    }
    
    // MARK: - Utility Methods
    
    /// Get a human-readable description of when something is due
    /// - Parameter date: Due date
    /// - Returns: Human-readable string
    func getDueDescription(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today at \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if daysDiff < 7 && daysDiff > 0 {
                return "In \(daysDiff) days at \(date.formatted(date: .omitted, time: .shortened))"
            } else if daysDiff < 0 && daysDiff > -7 {
                return "\(abs(daysDiff)) days ago at \(date.formatted(date: .omitted, time: .shortened))"
            } else {
                return date.formatted(date: .abbreviated, time: .shortened)
            }
        }
    }
}

// MARK: - Supporting Types

struct QuickTimeOption {
    let title: String
    let subtitle: String
    let date: Date
    let isDefault: Bool
}

struct SnoozeOption {
    let title: String
    let subtitle: String
    let interval: TimeInterval // seconds
}

// MARK: - Extensions

extension SchedulingService {
    /// Get default footer text for time selection
    var defaultTimeFooterText: String {
        let now = Date()
        let nextDue = calculateNextDueTime(from: now)
        return "Default: \(getDueDescription(for: nextDue))"
    }
}
