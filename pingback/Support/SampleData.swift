import Foundation

enum SampleData {
    #if DEBUG
    static func bootstrap() -> [FollowUp] {
        let now = Date()
        return [
            FollowUp(id: UUID(),
                     type: .doIt,
                     contactLabel: "Meera",
                     app: .whatsapp,
                     snippet: "I'll send the invoice by EOD",
                     verb: "send",
                     dueAt: Parser.shared.parse(text: "EOD", now: now, eodHour: 18, morningHour: 9)!.dueAt,
                     createdAt: now,
                     status: .open,
                     lastNudgedAt: nil),
            FollowUp(id: UUID(),
                     type: .waitingOn,
                     contactLabel: "Arjun",
                     app: .telegram,
                     snippet: "Can you share the deck tomorrow 10?",
                     verb: "share",
                     dueAt: Parser.shared.parse(text: "tomorrow 10", now: now, eodHour: 18, morningHour: 9)!.dueAt,
                     createdAt: now,
                     status: .open,
                     lastNudgedAt: nil),
            FollowUp(id: UUID(),
                     type: .doIt,
                     contactLabel: "Self",
                     app: .email,
                     snippet: "kal subah ping me for the payment",
                     verb: "ping",
                     dueAt: Parser.shared.parse(text: "kal subah", now: now, eodHour: 18, morningHour: 9)!.dueAt,
                     createdAt: now,
                     status: .open,
                     lastNudgedAt: nil)
        ]
    }
    #else
    static func bootstrap() -> [FollowUp] { [] }
    #endif
}


