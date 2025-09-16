import Foundation

@MainActor
final class FollowUpStore: ObservableObject {
    static let shared = FollowUpStore()
    
    @Published var items: [FollowUp] = []
    @Published var settings = Settings()
    
    // Computed property for compatibility with new code
    var followUps: [FollowUp] {
        return items
    }
    
    init() {
        // Initialize with sample data, but handle preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // For previews, use a simple fallback
            self.items = []
        } else {
            self.items = SampleData.bootstrap()
        }
    }

    struct Settings {
        var eodHour: Int = 18 // 6pm
        var morningHour: Int = 9
    }

    func add(from text: String,
             type: FollowType,
             contact: String,
             app: AppType,
             overrideDue: Date? = nil,
             now: Date = .now) {
        let parsed = Parser.shared.parse(text: text, now: now, eodHour: settings.eodHour, morningHour: settings.morningHour)
        let due = overrideDue ?? parsed?.dueAt ?? defaultDue(now: now)
        let _ = parsed?.verb ?? Parser.shared.detectVerb(in: text) ?? "follow up"
        let finalType = parsed?.type ?? type
        // Create a simple person from the contact string
        let person = Person(
            firstName: contact.isEmpty ? "Unknown" : contact,
            phoneNumbers: []
        )
        
        let item = FollowUp(
            id: UUID(),
            type: finalType,
            person: person,
            appType: app,
            note: text.trimmingCharacters(in: .whitespacesAndNewlines),
            dueAt: due,
            createdAt: now,
            status: .open,
            lastNudgedAt: nil
        )
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
    
    // MARK: - New Methods for Compatibility
    
    func addFollowUp(_ followUp: FollowUp) {
        items.append(followUp)
    }
    
    func updateFollowUp(_ followUp: FollowUp) {
        if let index = items.firstIndex(where: { $0.id == followUp.id }) {
            items[index] = followUp
        }
    }
    
    func loadFollowUps() {
        // Load follow-ups from shared storage (UserDefaults/CoreData)
        // For now, this is a placeholder - the existing init() handles sample data
        loadFromSharedStorage()
    }
    
    private func loadFromSharedStorage() {
        // Try to load from app group UserDefaults (shared with extension)
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            return
        }
        
        guard let data = appGroupDefaults.data(forKey: "shared_followups") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sharedFollowUps = try decoder.decode([FollowUp].self, from: data)
            
            // Add shared follow-ups to existing items (avoiding duplicates)
            for sharedFollowUp in sharedFollowUps {
                if !items.contains(where: { $0.id == sharedFollowUp.id }) {
                    items.append(sharedFollowUp)
                }
            }
            
            // Clear the shared storage after loading
            appGroupDefaults.removeObject(forKey: "shared_followups")
            appGroupDefaults.synchronize()
            
            print("✅ Loaded \(sharedFollowUps.count) follow-ups from shared storage")
        } catch {
            print("❌ Failed to load shared follow-ups: \(error)")
        }
    }
}


