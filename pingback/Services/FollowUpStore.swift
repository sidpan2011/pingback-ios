import Foundation

@MainActor
final class FollowUpStore: ObservableObject {
    @Published var items: [FollowUp] = SampleData.bootstrap()
    @Published var settings = Settings()

    struct Settings {
        var eodHour: Int = 18 // 6pm
        var morningHour: Int = 9
    }

    func add(from text: String,
             type: FollowType,
             contact: String,
             app: AppKind,
             overrideDue: Date? = nil,
             now: Date = .now) {
        let parsed = Parser.shared.parse(text: text, now: now, eodHour: settings.eodHour, morningHour: settings.morningHour)
        let due = overrideDue ?? parsed?.dueAt ?? defaultDue(now: now)
        let verb = parsed?.verb ?? Parser.shared.detectVerb(in: text) ?? "follow up"
        let finalType = parsed?.type ?? type
        let item = FollowUp(id: UUID(),
                            type: finalType,
                            contactLabel: contact.isEmpty ? "Unknown" : contact,
                            app: app,
                            snippet: text.trimmingCharacters(in: .whitespacesAndNewlines),
                            verb: verb,
                            dueAt: due,
                            createdAt: now,
                            status: .open,
                            lastNudgedAt: nil)
        items.append(item)
    }

    func markDone(_ item: FollowUp) {
        if let idx = items.firstIndex(of: item) {
            items[idx].status = .done
        }
    }

    func snooze(_ item: FollowUp, minutes: Int) {
        if let idx = items.firstIndex(of: item) {
            items[idx].dueAt = Calendar.current.date(byAdding: .minute, value: minutes, to: items[idx].dueAt) ?? items[idx].dueAt
            items[idx].status = .open
        }
    }

    private func defaultDue(now: Date) -> Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now
    }
}


