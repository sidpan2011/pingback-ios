import Foundation
import SwiftUI

/// Centralized preview provider for SwiftUI previews with in-memory Core Data stack
@MainActor
struct PreviewProvider {
    
    // MARK: - Core Data Stack
    
    static let coreDataStack = CoreDataStack.preview
    
    // MARK: - Stores
    
    static let followUpStore = NewFollowUpStore(coreDataStack: coreDataStack)
    static let userProfileStore = UserProfileStore(coreDataStack: coreDataStack)
    
    // MARK: - Sample Data
    
    /// Create sample follow-ups for previews (now empty - using Core Data only)
    static func createSampleFollowUps() async {
        // No longer creating sample follow-ups - using Core Data persistence
    }
    
    /// Create sample user profile for previews
    static func createSampleProfile() async {
        let sampleProfile = UserProfile(
            fullName: "Preview User",
            email: "preview@example.com",
            theme: "system"
        )
        
        do {
            try await userProfileStore.saveProfile(sampleProfile)
        } catch {
            print("Failed to create sample profile: \(error)")
        }
    }
    
    /// Initialize all sample data
    static func initializeSampleData() async {
        await createSampleProfile()
        await createSampleFollowUps()
    }
}

// MARK: - View Modifiers

extension View {
    /// Add stores to the environment for production
    func withStores() -> some View {
        self
            .environmentObject(NewFollowUpStore())
            .environmentObject(UserProfileStore())
    }
    
    /// Add preview stores to the environment
    func withPreviewStores() -> some View {
        self
            .environmentObject(PreviewProvider.followUpStore)
            .environmentObject(PreviewProvider.userProfileStore)
            .task {
                await PreviewProvider.initializeSampleData()
            }
    }
}
