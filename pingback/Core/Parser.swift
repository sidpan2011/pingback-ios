import Foundation

struct ParseResult {
    let type: FollowType
    let verb: String
    let dueAt: Date
}

final class Parser {
    static let shared = Parser()
    private init() {}

    func parse(text: String, now: Date, eodHour: Int, morningHour: Int) -> ParseResult? {
        let t = text.lowercased()

        // Actor/type
        let type: FollowType = {
            if t.containsAny(of: ["can you", "could you", "pls", "please", "when can you", "share the"]) {
                return .waitingOn
            }
            if t.containsAny(of: ["i'll", "i will", "i can", "got it", "i shall"]) {
                return .doIt
            }
            return .doIt
        }()

        // Verb
        let verb = detectVerb(in: t) ?? "follow up"

        // Due time
        if t.containsWord("eod") || t.contains("end of day") {
            return ParseResult(type: type, verb: verb, dueAt: TimeResolver.todayAt(hour: eodHour, minute: 0, from: now))
        }
        if t.containsWord("eow") || t.contains("end of week") {
            return ParseResult(type: type, verb: verb, dueAt: TimeResolver.upcoming(.friday, atHour: eodHour, from: now))
        }
        if t.containsAny(of: ["tonight"]) {
            return ParseResult(type: type, verb: verb, dueAt: TimeResolver.todayAt(hour: 21, minute: 0, from: now))
        }
        if t.containsAny(of: ["tomorrow", "tmrw", "tmr", "kal "]) {
            // Try to find explicit hour
            if let hm = hourMinute(in: t) {
                return ParseResult(type: type, verb: verb, dueAt: TimeResolver.tomorrowAt(hour: hm.h, minute: hm.m, from: now))
            } else if t.containsAny(of: ["kal subah", "tomorrow morning"]) {
                return ParseResult(type: type, verb: verb, dueAt: TimeResolver.tomorrowAt(hour: morningHour, minute: 0, from: now))
            } else if t.containsAny(of: ["kal shaam", "tomorrow evening"]) {
                return ParseResult(type: type, verb: verb, dueAt: TimeResolver.tomorrowAt(hour: 19, minute: 0, from: now))
            } else {
                return ParseResult(type: type, verb: verb, dueAt: TimeResolver.tomorrowAt(hour: morningHour, minute: 0, from: now))
            }
        }
        if let weekday = nextWeekday(in: t) {
            let hour = hourMinute(in: t)?.h ?? morningHour
            let minute = hourMinute(in: t)?.m ?? 0
            return ParseResult(type: type, verb: verb, dueAt: TimeResolver.next(weekday, atHour: hour, minute: minute, from: now))
        }
        if let (h, m, isPM) = timeOfDay(in: t) {
            let hour24 = TimeResolver.to24Hour(h: h, isPM: isPM)
            return ParseResult(type: type, verb: verb, dueAt: TimeResolver.todayAt(hour: hour24, minute: m, from: now))
        }

        return nil
    }

    func detectVerb(in text: String) -> String? {
        // Keep this ultra-simple to avoid Preview type-check blowups from large literals/macros.
        if text.contains("send") { return "send" }
        if text.contains("share") { return "share" }
        if text.contains("invoice") { return "invoice" }
        if text.contains("deck") { return "deck" }
        if text.contains("call") { return "call" }
        if text.contains("pay") { return "pay" }
        if text.contains("submit") { return "submit" }
        if text.contains("status") { return "status" }
        if text.contains("update") { return "update" }
        if text.contains("follow up") { return "follow up" }
        if text.contains("remind") { return "remind" }
        if text.contains("ping") { return "ping" }
        return nil
    }

    // MARK: - Helpers

    private func hourMinute(in text: String) -> (h: Int, m: Int)? {
        // matches "10", "10:30"
        let tokens = text.split(whereSeparator: { !$0.isNumber && $0 != ":" }).map(String.init)
        for t in tokens {
            if t.contains(":"), let h = Int(t.split(separator: ":").first ?? ""), let m = Int(t.split(separator: ":").last ?? "") {
                if (0...23).contains(h), (0...59).contains(m) { return (h, m) }
            } else if let h = Int(t), (0...23).contains(h) {
                return (h, 0)
            }
        }
        return nil
    }

    private func timeOfDay(in text: String) -> (h: Int, m: Int, isPM: Bool)? {
        // matches "10am", "10 pm", "10:30 PM"
        let lower = text.replacingOccurrences(of: " ", with: "")
        guard let ampmRange = lower.range(of: "am") ?? lower.range(of: "pm") else { return nil }
        let isPM = lower[ampmRange] == "pm"
        let prefix = String(lower[..<ampmRange.lowerBound])
        if let idx = prefix.lastIndex(where: { $0.isNumber == false }) {
            let timeToken = String(prefix[prefix.index(after: idx)...])
            if timeToken.contains(":"), let h = Int(timeToken.split(separator: ":").first ?? ""), let m = Int(timeToken.split(separator: ":").last ?? "") {
                return (h, m, isPM)
            } else if let h = Int(timeToken) {
                return (h, 0, isPM)
            }
        } else if let h = Int(prefix) {
            return (h, 0, isPM)
        }
        return nil
    }

    private func nextWeekday(in text: String) -> Weekday? {
        if text.contains("next mon") || text.contains("next monday") { return .monday }
        if text.contains("next tue") || text.contains("next tuesday") { return .tuesday }
        if text.contains("next wed") || text.contains("next wednesday") { return .wednesday }
        if text.contains("next thu") || text.contains("next thursday") { return .thursday }
        if text.contains("next fri") || text.contains("next friday") { return .friday }
        if text.contains("next sat") || text.contains("next saturday") { return .saturday }
        if text.contains("next sun") || text.contains("next sunday") { return .sunday }
        return nil
    }
}


