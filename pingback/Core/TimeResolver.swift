import Foundation

enum TimeResolver {
    static func todayAt(hour: Int, minute: Int, from now: Date) -> Date {
        var cal = Calendar.current
        cal.timeZone = .current
        let comps = cal.dateComponents([.year,.month,.day], from: now)
        return cal.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: hour, minute: minute)) ?? now
    }

    static func tomorrowAt(hour: Int, minute: Int, from now: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayAt(hour: hour, minute: minute, from: now)) ?? now
    }

    static func upcoming(_ weekday: Weekday, atHour hour: Int, from now: Date) -> Date {
        next(weekday, atHour: hour, minute: 0, from: now)
    }

    static func next(_ weekday: Weekday, atHour hour: Int, minute: Int, from now: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let comp = cal.dateComponents([.year,.month,.day,.weekday], from: now)
        let current = Weekday(rawValue: comp.weekday ?? 1) ?? .monday
        var days = (weekday.order - current.order + 7) % 7
        if days == 0 { days = 7 }
        let base = cal.date(byAdding: .day, value: days, to: now) ?? now
        let nextComps = cal.dateComponents([.year,.month,.day], from: base)
        return cal.date(from: DateComponents(year: nextComps.year, month: nextComps.month, day: nextComps.day, hour: hour, minute: minute)) ?? now
    }

    static func to24Hour(h: Int, isPM: Bool) -> Int {
        var hour = h % 12
        if isPM { hour += 12 }
        return hour
    }
}


