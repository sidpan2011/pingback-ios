import Foundation
import CoreData
import SwiftUI

/// Store for managing FollowUp entities with async CRUD operations and optimized queries
@MainActor
final class NewFollowUpStore: ObservableObject {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    private let notificationManager: NotificationManager
    
    @Published var followUps: [FollowUp] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var settings = Settings()
    
    struct Settings {
        var eodHour: Int = 18 // 6pm
        var morningHour: Int = 9
    }
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack = .shared, notificationManager: NotificationManager = .shared) {
        self.coreDataStack = coreDataStack
        self.notificationManager = notificationManager
        print("🚀 NewFollowUpStore: Initializing store")
        
        // Load follow-ups from Core Data on initialization
        Task {
            await loadFollowUps()
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new follow-up
    func create(_ followUp: FollowUp) async throws {
        print("➕ NewFollowUpStore: Creating new follow-up")
        print("   - ID: \(followUp.id.uuidString)")
        print("   - Snippet: '\(followUp.snippet)'")
        print("   - ContactLabel: '\(followUp.contactLabel)'")
        print("   - Verb: '\(followUp.verb)'")
        print("   - Type: \(followUp.type.rawValue)")
        print("   - App: \(followUp.app.rawValue)")
        print("   - DueAt: \(followUp.dueAt)")
        
        // Use main context for both read and write to avoid context sync issues
        let cdFollowUp = try await MainActor.run {
            let context = coreDataStack.viewContext
            let cdFollowUp = CDFollowUp(context: context)
            self.mapFollowUpToCoreData(followUp, to: cdFollowUp)
            
            print("💾 NewFollowUpStore: Mapped to Core Data entity:")
            print("   - ID: \(cdFollowUp.id?.uuidString ?? "nil")")
            print("   - Title: '\(cdFollowUp.title ?? "nil")'")
            print("   - Snippet: '\(cdFollowUp.snippet ?? "nil")'")
            print("   - ContactLabel: '\(cdFollowUp.contactLabel ?? "nil")'")
            print("   - Verb: '\(cdFollowUp.verb ?? "nil")'")
            print("   - Type: '\(cdFollowUp.type ?? "nil")'")
            print("   - App: '\(cdFollowUp.app ?? "nil")'")
            
            try self.coreDataStack.saveWithTimestamp(context)
            print("💾 NewFollowUpStore: Successfully saved to Core Data")
            
            return cdFollowUp
        }
        
        // Schedule creation nudge notification
        await notificationManager.scheduleCreationNudge(for: cdFollowUp)
        
        print("🔄 NewFollowUpStore: Reloading follow-ups after create")
        await loadFollowUps()
        
        // Schedule notification for the new follow-up
        await notificationManager.scheduleNotification(for: cdFollowUp)
    }
    
    /// Update an existing follow-up
    func update(_ followUp: FollowUp) async throws {
        print("✏️ NewFollowUpStore: Updating follow-up \(followUp.id.uuidString)")
        print("   - Snippet: '\(followUp.snippet)'")
        print("   - ContactLabel: '\(followUp.contactLabel)'")
        print("   - Verb: '\(followUp.verb)'")
        
        let cdFollowUp = try await MainActor.run {
            let context = coreDataStack.viewContext
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", followUp.id as CVarArg)
            request.fetchLimit = 1
            
            guard let cdFollowUp = try context.fetch(request).first else {
                print("❌ NewFollowUpStore: Follow-up not found for update: \(followUp.id.uuidString)")
                throw FollowUpStoreError.notFound
            }
            
            print("🔍 NewFollowUpStore: Found existing follow-up in Core Data")
            self.mapFollowUpToCoreData(followUp, to: cdFollowUp)
            try self.coreDataStack.saveWithTimestamp(context)
            print("💾 NewFollowUpStore: Successfully updated in Core Data")
            
            return cdFollowUp
        }
        
        print("🔄 NewFollowUpStore: Reloading follow-ups after update")
        await loadFollowUps()
        
        // Reschedule notification for the updated follow-up
        await notificationManager.scheduleNotification(for: cdFollowUp)
    }
    
    /// Delete a follow-up (soft delete)
    func delete(_ followUp: FollowUp) async throws {
        try await softDelete(id: followUp.id)
    }
    
    /// Soft delete by ID
    func softDelete(id: UUID) async throws {
        print("🗑️ NewFollowUpStore: Soft deleting follow-up \(id.uuidString)")
        
        try await MainActor.run {
            let context = coreDataStack.viewContext
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let cdFollowUp = try context.fetch(request).first else {
                print("❌ NewFollowUpStore: Follow-up not found for deletion: \(id.uuidString)")
                throw FollowUpStoreError.notFound
            }
            
            cdFollowUp.deletedAt = Date()
            try self.coreDataStack.saveWithTimestamp(context)
            print("🗑️ NewFollowUpStore: Successfully soft deleted follow-up")
        }
        
        // Cancel notification for deleted follow-up
        await notificationManager.cancelNotification(for: id)
        
        print("🔄 NewFollowUpStore: Reloading follow-ups after delete")
        await loadFollowUps()
    }
    
    /// Mark follow-up as completed
    func markCompleted(_ followUp: FollowUp, completed: Bool = true) async throws {
        var updatedFollowUp = followUp
        updatedFollowUp.status = completed ? .done : .open
        try await update(updatedFollowUp)
        
        // Cancel notification if marking as completed
        if completed {
            await notificationManager.cancelNotification(for: followUp.id)
        }
        
        // Update badge count
        await notificationManager.updateBadgeCount()
    }
    
    /// Snooze a follow-up
    func snooze(_ followUp: FollowUp, until date: Date) async throws {
        // Update the Core Data entity with snooze information
        let cdFollowUp = try await MainActor.run {
            let context = coreDataStack.viewContext
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", followUp.id as CVarArg)
            request.fetchLimit = 1
            
            guard let cdFollowUp = try context.fetch(request).first else {
                throw FollowUpStoreError.notFound
            }
            
            cdFollowUp.snoozedUntil = date
            cdFollowUp.status = Status.snoozed.rawValue
            try self.coreDataStack.saveWithTimestamp(context)
            
            return cdFollowUp
        }
        
        // Reschedule notification with new snooze time
        await notificationManager.scheduleNotification(for: cdFollowUp)
        
        await loadFollowUps()
    }
    
    /// Add a new follow-up (compatible with old FollowUpStore interface)
    func add(from text: String,
             type: FollowType,
             contact: String,
             app: AppKind,
             url: String? = nil,
             overrideDue: Date? = nil,
             now: Date = .now) async throws {
        print("🏪 NewFollowUpStore.add() called with:")
        print("   - Text: \(String(text.prefix(100)))")
        print("   - Type: \(type)")
        print("   - Contact: \(contact)")
        print("   - App: \(app)")
        print("   - URL: \(url ?? "nil")")
        print("   - Current follow-ups count before add: \(await followUps.count)")
        
        let parsed = Parser.shared.parse(text: text, now: now, eodHour: settings.eodHour, morningHour: settings.morningHour)
        let due = overrideDue ?? parsed?.dueAt ?? defaultDue(now: now)
        let verb = parsed?.verb ?? Parser.shared.detectVerb(in: text) ?? "follow up"
        let finalType = parsed?.type ?? type
        
        let followUp = FollowUp(
            id: UUID(),
            type: finalType,
            contactLabel: contact.isEmpty ? "Unknown" : contact,
            app: app,
            snippet: text.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url,
            verb: verb,
            dueAt: due,
            createdAt: now,
            status: .open,
            lastNudgedAt: nil
        )
        
        print("🔍 NewFollowUpStore: === CREATING FOLLOWUP OBJECT ===")
        print("   - ID: \(followUp.id)")
        print("   - Type: \(followUp.type)")
        print("   - ContactLabel: '\(followUp.contactLabel)'")
        print("   - App: \(followUp.app) (\(followUp.app.rawValue))")
        print("   - Snippet: '\(String(followUp.snippet.prefix(50)))'")
        print("   - URL: '\(followUp.url ?? "nil")'")
        print("   - Verb: '\(followUp.verb)'")
        print("   - Status: \(followUp.status)")
        
        print("🏪 NewFollowUpStore: Creating follow-up with ID: \(followUp.id)")
        print("   - Follow-up details:")
        print("     - Snippet: \(String(followUp.snippet.prefix(50)))")
        print("     - Contact: \(followUp.contactLabel)")
        print("     - App: \(followUp.app.rawValue)")
        print("     - Type: \(followUp.type.rawValue)")
        print("     - Due: \(followUp.dueAt)")
        
        try await create(followUp)
        print("✅ NewFollowUpStore: Successfully created follow-up!")
        print("   - Current follow-ups count after add: \(await followUps.count)")
    }
    
    /// Mark a follow-up as done (compatible with old FollowUpStore interface)
    func markDone(_ followUp: FollowUp) {
        Task {
            do {
                try await markCompleted(followUp, completed: true)
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    /// Snooze a follow-up by minutes (compatible with old FollowUpStore interface)
    func snooze(_ followUp: FollowUp, minutes: Int) {
        let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        Task {
            do {
                try await snooze(followUp, until: snoozeDate)
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    /// Provide items property for compatibility
    var items: [FollowUp] {
        followUps
    }
    
    /// Default due date calculation
    private func defaultDue(now: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        if hour < 18 {
            // Before 6 PM, due today at 6 PM
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        } else {
            // After 6 PM, due tomorrow at 9 AM
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? now
        }
    }
    
    // MARK: - Queries
    
    /// Load all active follow-ups
    func loadFollowUps() async {
        print("🔄 NewFollowUpStore: Starting to load follow-ups from Core Data")
        isLoading = true
        error = nil
        
        do {
            let cdFollowUps = try await fetchActiveFollowUps()
            print("📊 NewFollowUpStore: Fetched \(cdFollowUps.count) follow-ups from Core Data")
            
            // Log each Core Data entity before mapping
            for (index, cdFollowUp) in cdFollowUps.enumerated() {
                print("📝 Core Data FollowUp \(index):")
                print("   - ID: \(cdFollowUp.id?.uuidString ?? "nil")")
                print("   - Title: '\(cdFollowUp.title ?? "nil")'")
                print("   - Snippet: '\(cdFollowUp.snippet ?? "nil")'")
                print("   - ContactLabel: '\(cdFollowUp.contactLabel ?? "nil")'")
                print("   - Verb: '\(cdFollowUp.verb ?? "nil")'")
                print("   - Type: '\(cdFollowUp.type ?? "nil")'")
                print("   - App: '\(cdFollowUp.app ?? "nil")'")
                print("   - DueAt: \(cdFollowUp.dueAt?.description ?? "nil")")
            }
            
            let followUps = cdFollowUps.map(mapCoreDataToFollowUp)
            print("🔄 NewFollowUpStore: Mapped to \(followUps.count) FollowUp models")
            
            // Log each mapped FollowUp
            for (index, followUp) in followUps.enumerated() {
                print("📱 Mapped FollowUp \(index):")
                print("   - ID: \(followUp.id.uuidString)")
                print("   - Snippet: '\(followUp.snippet)'")
                print("   - ContactLabel: '\(followUp.contactLabel)'")
                print("   - Verb: '\(followUp.verb)'")
                print("   - Type: \(followUp.type.rawValue)")
                print("   - App: \(followUp.app.rawValue)")
            }
            
            await MainActor.run {
                self.followUps = followUps
                self.isLoading = false
                print("✅ NewFollowUpStore: Successfully loaded \(followUps.count) follow-ups")
            }
        } catch {
            print("❌ NewFollowUpStore: Error loading follow-ups: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    /// Fetch follow-ups due today
    func fetchDueToday() async throws -> [FollowUp] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            request.predicate = NSPredicate(
                format: "deletedAt == nil AND dueAt >= %@ AND dueAt < %@",
                today as NSDate,
                tomorrow as NSDate
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "dueAt", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            let cdFollowUps = try context.fetch(request)
            return cdFollowUps.map(self.mapCoreDataToFollowUp)
        }
    }
    
    /// Fetch overdue follow-ups
    func fetchOverdue() async throws -> [FollowUp] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            request.predicate = NSPredicate(
                format: "deletedAt == nil AND dueAt < %@ AND status != %@",
                Date() as NSDate,
                Status.done.rawValue
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "dueAt", ascending: true)
            ]
            
            let cdFollowUps = try context.fetch(request)
            return cdFollowUps.map(self.mapCoreDataToFollowUp)
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchActiveFollowUps() async throws -> [CDFollowUp] {
        return try await MainActor.run {
            let context = coreDataStack.viewContext
            let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
            
            // Only fetch active (non-deleted) follow-ups
            request.predicate = NSPredicate(format: "deletedAt == nil")
            
            // Optimize sorting: due items first, then by creation date
            request.sortDescriptors = [
                NSSortDescriptor(key: "dueAt", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            // Performance: limit initial load
            request.fetchLimit = 100
            
            return try context.fetch(request)
        }
    }
    
    private func mapCoreDataToFollowUp(_ cdFollowUp: CDFollowUp) -> FollowUp {
        return FollowUp(
            id: cdFollowUp.id ?? UUID(),
            type: FollowType(rawValue: cdFollowUp.type ?? "") ?? .doIt,
            contactLabel: cdFollowUp.contactLabel ?? "",
            app: AppKind(rawValue: cdFollowUp.app ?? "") ?? .other,
            snippet: cdFollowUp.snippet ?? "",
            url: cdFollowUp.webURL,
            verb: cdFollowUp.verb ?? "",
            dueAt: cdFollowUp.dueAt ?? Date(),
            createdAt: cdFollowUp.createdAt ?? Date(),
            status: Status(rawValue: cdFollowUp.status ?? "") ?? .open,
            lastNudgedAt: cdFollowUp.lastNudgedAt
        )
    }
    
    private func mapFollowUpToCoreData(_ followUp: FollowUp, to cdFollowUp: CDFollowUp) {
        cdFollowUp.id = followUp.id
        cdFollowUp.title = followUp.snippet // Using snippet as title for now
        cdFollowUp.type = followUp.type.rawValue
        cdFollowUp.contactLabel = followUp.contactLabel
        cdFollowUp.app = followUp.app.rawValue
        cdFollowUp.snippet = followUp.snippet
        cdFollowUp.webURL = followUp.url
        cdFollowUp.verb = followUp.verb
        cdFollowUp.dueAt = followUp.dueAt
        cdFollowUp.status = followUp.status.rawValue
        cdFollowUp.lastNudgedAt = followUp.lastNudgedAt
        cdFollowUp.isCompleted = followUp.status == .done
        
        // Set notification-related fields
        if cdFollowUp.shouldNotify == false { // Only set if not already set
            cdFollowUp.shouldNotify = true
        }
        if cdFollowUp.creationTimeZone == nil {
            cdFollowUp.creationTimeZone = TimeZone.current.identifier
        }
        
        // Set timestamps if this is a new entity
        if cdFollowUp.createdAt == nil {
            cdFollowUp.createdAt = followUp.createdAt
        }
        // updatedAt will be set by saveWithTimestamp
    }
}

// MARK: - Error Types

enum FollowUpStoreError: LocalizedError {
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Follow-up not found"
        case .invalidData:
            return "Invalid follow-up data"
        }
    }
}

// MARK: - Preview Support

extension NewFollowUpStore {
    static var preview: NewFollowUpStore {
        NewFollowUpStore(coreDataStack: .preview)
    }
}
