import Foundation
import CoreData

class CoreDataFollowUpRepository: FollowUpRepository {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    func upsert(_ item: FollowUpDTO) throws {
        let context = persistenceController.container.viewContext
        
        // Try to find existing item
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        
        let existingItems = try context.fetch(request)
        
        if let existingItem = existingItems.first {
            // Update existing item
            updateCDFollowUp(existingItem, with: item)
        } else {
            // Create new item
            let newItem = CDFollowUp(context: context)
            updateCDFollowUp(newItem, with: item)
        }
        
        try context.save()
    }
    
    func softDelete(id: String, at now: Double) throws {
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let items = try context.fetch(request)
        if let item = items.first {
            item.deletedAt = Date(timeIntervalSince1970: now)
            try context.save()
        }
    }
    
    func markCompleted(_ id: String, completed: Bool, now: Double) throws {
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let items = try context.fetch(request)
        if let item = items.first {
            item.isCompleted = completed
            item.updatedAt = Date(timeIntervalSince1970: now)
            try context.save()
        }
    }
    
    func fetchPage(limit: Int, after dueAt: Double?) throws -> [FollowUpDTO] {
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.fetchLimit = limit
        
        // Filter out soft deleted items
        request.predicate = NSPredicate(format: "deletedAt == nil")
        
        // Sort by dueAt (NULLS LAST)
        let dueAtSort = NSSortDescriptor(key: "dueAt", ascending: true)
        let createdAtSort = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [dueAtSort, createdAtSort]
        
        if let dueAt = dueAt {
            request.predicate = NSPredicate(format: "deletedAt == nil AND dueAt > %@", Date(timeIntervalSince1970: dueAt) as NSDate)
        }
        
        let items = try context.fetch(request)
        return items.map { convertToDTO($0) }
    }
    
    func fetchAll() throws -> [FollowUpDTO] {
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<CDFollowUp> = CDFollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil")
        
        let items = try context.fetch(request)
        return items.map { convertToDTO($0) }
    }
    
    private func updateCDFollowUp(_ cdItem: CDFollowUp, with dto: FollowUpDTO) {
        cdItem.id = UUID(uuidString: dto.id) ?? UUID()
        cdItem.title = dto.title
        cdItem.notes = dto.notes
        cdItem.dueAt = dto.dueAt.map { Date(timeIntervalSince1970: $0) }
        cdItem.isCompleted = dto.isCompleted
        cdItem.webURL = dto.urlString
        cdItem.createdAt = Date(timeIntervalSince1970: dto.createdAt)
        cdItem.updatedAt = Date(timeIntervalSince1970: dto.updatedAt)
        cdItem.deletedAt = dto.deletedAt.map { Date(timeIntervalSince1970: $0) }
        cdItem.type = dto.type
        cdItem.contactLabel = dto.contactLabel
        cdItem.app = dto.app
        cdItem.snippet = dto.snippet
        cdItem.verb = dto.verb
        cdItem.status = dto.status
        cdItem.lastNudgedAt = dto.lastNudgedAt.map { Date(timeIntervalSince1970: $0) }
    }
    
    private func convertToDTO(_ cdItem: CDFollowUp) -> FollowUpDTO {
        return FollowUpDTO(
            id: cdItem.id?.uuidString ?? UUID().uuidString,
            title: cdItem.title ?? "",
            notes: cdItem.notes,
            dueAt: cdItem.dueAt?.timeIntervalSince1970,
            isCompleted: cdItem.isCompleted,
            urlString: cdItem.webURL,
            createdAt: cdItem.createdAt?.timeIntervalSince1970 ?? 0,
            updatedAt: cdItem.updatedAt?.timeIntervalSince1970 ?? 0,
            deletedAt: cdItem.deletedAt?.timeIntervalSince1970,
            type: cdItem.type ?? "",
            contactLabel: cdItem.contactLabel ?? "",
            app: cdItem.app ?? "",
            snippet: cdItem.snippet ?? "",
            verb: cdItem.verb ?? "",
            status: cdItem.status ?? "",
            lastNudgedAt: cdItem.lastNudgedAt?.timeIntervalSince1970
        )
    }
}
