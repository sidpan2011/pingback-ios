import Foundation

struct FollowUpDTO: Codable {
    var id: String
    var title: String
    var notes: String?
    var dueAt: Double?
    var isCompleted: Bool
    var urlString: String?
    var createdAt: Double
    var updatedAt: Double
    var deletedAt: Double?
    // Additional fields from FollowUp model
    var type: String
    var contactLabel: String
    var app: String
    var snippet: String
    var verb: String
    var status: String
    var lastNudgedAt: Double?
}

protocol FollowUpRepository {
    func upsert(_ item: FollowUpDTO) throws
    func softDelete(id: String, at now: Double) throws
    func markCompleted(_ id: String, completed: Bool, now: Double) throws
    func fetchPage(limit: Int, after dueAt: Double?) throws -> [FollowUpDTO] // newest by dueAt NULLS LAST
    func fetchAll() throws -> [FollowUpDTO]
}
