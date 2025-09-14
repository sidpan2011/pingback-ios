import CoreData
import Foundation

/// A robust Core Data stack with automatic lightweight migrations, proper context configuration,
/// and helper methods for background operations.
final class CoreDataStack: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    private let modelName: String
    private let inMemory: Bool
    
    /// The main persistent container
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure store description for automatic migrations
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            // Performance optimizations
            storeDescription.setValue("WAL" as NSString, forPragmaNamed: "journal_mode")
            storeDescription.setValue("1" as NSString, forPragmaNamed: "synchronous")
        }
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                self?.handlePersistentStoreError(error)
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil // Disable undo for performance
        
        return container
    }()
    
    /// The main view context - use for reads and UI updates
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    
    /// Initialize with production settings
    private init() {
        self.modelName = "Pingback"
        self.inMemory = false
    }
    
    /// Initialize for testing/previews
    init(inMemory: Bool) {
        self.modelName = "Pingback"
        self.inMemory = inMemory
    }
    
    // MARK: - Background Context Operations
    
    /// Create a new background context for write operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    /// Perform a task on a background context
    func performBackgroundTask<T>(_ task: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try task(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Save Operations
    
    /// Save the main view context
    func save() throws {
        try saveContext(viewContext)
    }
    
    /// Save any context with proper error handling
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            // Log error details for debugging
            print("Core Data save error: \(error)")
            if let nsError = error as NSError? {
                print("Error details: \(nsError.userInfo)")
            }
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Save context and update timestamps
    func saveWithTimestamp(_ context: NSManagedObjectContext, timestamp: Date = Date()) throws {
        // Update timestamps for inserted and updated objects
        updateTimestamps(in: context, timestamp: timestamp)
        try saveContext(context)
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch update operation
    func batchUpdate<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate?,
        propertiesToUpdate: [String: Any]
    ) async throws {
        try await performBackgroundTask { context in
            let batchUpdate = NSBatchUpdateRequest(entityName: String(describing: entityType))
            batchUpdate.predicate = predicate
            batchUpdate.propertiesToUpdate = propertiesToUpdate
            batchUpdate.resultType = .updatedObjectsCountResultType
            
            let result = try context.execute(batchUpdate) as? NSBatchUpdateResult
            print("Batch update completed: \(result?.result ?? 0) objects updated")
        }
    }
    
    /// Perform batch delete operation
    func batchDelete<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate
    ) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            
            // Merge changes to view context
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
            }
        }
    }
    
    // MARK: - Fetch Helpers
    
    /// Execute a fetch request with error handling
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            throw CoreDataError.fetchFailed(error)
        }
    }
    
    /// Count objects matching a predicate
    func count<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil
    ) throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Count error: \(error)")
            throw CoreDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateTimestamps(in context: NSManagedObjectContext, timestamp: Date) {
        // Update createdAt for inserted objects
        for object in context.insertedObjects {
            if let followUp = object as? CDFollowUp {
                if followUp.createdAt == nil {
                    followUp.createdAt = timestamp
                }
                followUp.updatedAt = timestamp
            }
        }
        
        // Update updatedAt for updated objects
        for object in context.updatedObjects {
            if let followUp = object as? CDFollowUp {
                followUp.updatedAt = timestamp
            }
        }
    }
    
    private func handlePersistentStoreError(_ error: Error) {
        print("Failed to load persistent store: \(error)")
        
        // In production, you might want to:
        // 1. Try to recover from the error
        // 2. Delete and recreate the store if corrupted
        // 3. Report to crash analytics
        // For now, we'll just log and continue
        
        #if DEBUG
        print("Core Data store failed to load in DEBUG mode: \(error)")
        // Don't crash in DEBUG mode, just log the error
        #endif
    }
}

// MARK: - Preview Support

extension CoreDataStack {
    /// Create an in-memory stack for SwiftUI previews
    nonisolated static var preview: CoreDataStack = {
        let stack = CoreDataStack(inMemory: true)
        
        // Pre-populate with sample data
        let context = stack.viewContext
        
        // Sample FollowUp
        let followUp = CDFollowUp(context: context)
        followUp.id = UUID()
        followUp.title = "Sample Follow-up"
        followUp.notes = "This is a sample follow-up for preview"
        followUp.dueAt = Date().addingTimeInterval(3600)
        followUp.isCompleted = false
        followUp.createdAt = Date()
        followUp.updatedAt = Date()
        followUp.type = "DO"
        followUp.contactLabel = "John Doe"
        followUp.app = "whatsapp"
        followUp.snippet = "Follow up on project status"
        followUp.verb = "follow up"
        followUp.status = "open"
        
        // Sample UserProfile
        let profile = CDUserProfile(context: context)
        profile.id = UUID()
        profile.fullName = "Preview User"
        profile.email = "preview@example.com"
        profile.theme = "system"
        
        do {
            try stack.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }
        
        return stack
    }()
}

// MARK: - Error Types

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Failed to migrate data: \(error.localizedDescription)"
        }
    }
}

