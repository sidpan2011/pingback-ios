import Foundation
import CoreData
import SwiftUI

/// Store for managing user profile with Core Data persistence
@MainActor
final class UserProfileStore: ObservableObject {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        Task {
            await loadProfile()
        }
    }
    
    // MARK: - Profile Operations
    
    /// Load the user profile
    func loadProfile() async {
        isLoading = true
        error = nil
        
        do {
            if let cdProfile = try await fetchProfile() {
                let profile = mapCoreDataToUserProfile(cdProfile)
                await MainActor.run {
                    self.profile = profile
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.profile = nil
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    /// Save or update the user profile
    func saveProfile(_ profile: UserProfile) async throws {
        print("💾 UserProfileStore: Saving profile")
        print("   - Full Name: '\(profile.fullName)'")
        print("   - Email: '\(profile.email ?? "nil")'")
        
        try await MainActor.run {
            let context = coreDataStack.viewContext
            let cdProfile: CDUserProfile
            
            // Try to find existing profile
            if let existingProfile = try self.fetchProfile(in: context) {
                cdProfile = existingProfile
                print("   - Updating existing profile")
            } else {
                cdProfile = CDUserProfile(context: context)
                cdProfile.id = UUID()
                print("   - Creating new profile")
            }
            
            // Update profile data
            self.mapUserProfileToCoreData(profile, to: cdProfile)
            
            try self.coreDataStack.saveContext(context)
            print("✅ UserProfileStore: Profile saved successfully")
            
            // Update the existing profile instance instead of creating a new one
            if let existingProfile = self.profile {
                existingProfile.fullName = profile.fullName
                existingProfile.email = profile.email
                existingProfile.avatarData = profile.avatarData
                existingProfile.theme = profile.theme
            } else {
                self.profile = profile
            }
        }
    }
    
    /// Update profile theme
    func updateTheme(_ theme: String) async throws {
        guard let currentProfile = profile else { return }
        
        currentProfile.theme = theme
        try await saveProfile(currentProfile)
    }
    
    /// Update profile name
    func updateName(_ name: String) async throws {
        guard let currentProfile = profile else { return }
        
        currentProfile.fullName = name
        try await saveProfile(currentProfile)
    }
    
    /// Update profile email
    func updateEmail(_ email: String?) async throws {
        guard let currentProfile = profile else { return }
        
        currentProfile.email = email
        try await saveProfile(currentProfile)
    }
    
    /// Update profile avatar
    func updateAvatar(_ avatarData: Data?) async throws {
        guard let currentProfile = profile else { return }
        
        // Update the avatar data on the main actor to ensure UI updates
        await MainActor.run {
            currentProfile.avatarData = avatarData
        }
        
        try await saveProfile(currentProfile)
    }
    
    /// Reset profile to defaults
    func resetProfile() async throws {
        try await MainActor.run {
            let context = coreDataStack.viewContext
            if let existingProfile = try self.fetchProfile(in: context) {
                context.delete(existingProfile)
                try self.coreDataStack.saveContext(context)
            }
        }
        
        await loadProfile()
    }
    
    /// Check if profile is complete
    var isProfileComplete: Bool {
        guard let profile = profile else { return false }
        return !profile.fullName.isEmpty && !(profile.email?.isEmpty ?? true)
    }
    
    // MARK: - Private Helpers
    
    private func fetchProfile() async throws -> CDUserProfile? {
        return try await MainActor.run {
            return try self.fetchProfile(in: coreDataStack.viewContext)
        }
    }
    
    private func fetchProfile(in context: NSManagedObjectContext) throws -> CDUserProfile? {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.fetchLimit = 1
        
        let profiles = try context.fetch(request)
        return profiles.first
    }
    
    private func mapCoreDataToUserProfile(_ cdProfile: CDUserProfile) -> UserProfile {
        let profile = UserProfile(
            fullName: cdProfile.fullName ?? "",
            email: cdProfile.email,
            avatarData: cdProfile.avatarData,
            theme: cdProfile.theme ?? "system"
        )
        return profile
    }
    
    private func mapUserProfileToCoreData(_ profile: UserProfile, to cdProfile: CDUserProfile) {
        cdProfile.fullName = profile.fullName
        cdProfile.email = profile.email
        cdProfile.avatarData = profile.avatarData
        cdProfile.theme = profile.theme
    }
}

// MARK: - Preview Support

extension UserProfileStore {
    static var preview: UserProfileStore {
        let store = UserProfileStore(coreDataStack: .preview)
        store.profile = UserProfile(
            fullName: "Preview User",
            email: "preview@example.com",
            theme: "system"
        )
        return store
    }
}
