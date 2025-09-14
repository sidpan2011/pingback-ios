import Foundation
import SwiftUI

class UserProfile: ObservableObject, Equatable {
    @Published var fullName: String
    @Published var email: String?
    @Published var avatarData: Data?
    @Published var theme: String
    
    init(fullName: String = "", email: String? = nil, avatarData: Data? = nil, theme: String = "system") {
        self.fullName = fullName
        self.email = email
        self.avatarData = avatarData
        self.theme = theme
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return (first + last).uppercased()
        } else if !fullName.isEmpty {
            return String(fullName.prefix(2)).uppercased()
        }
        return "U"
    }
    
    var isProfileIncomplete: Bool {
        return fullName.isEmpty || email?.isEmpty ?? true
    }
    
    // MARK: - Equatable
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.fullName == rhs.fullName &&
               lhs.email == rhs.email &&
               lhs.avatarData == rhs.avatarData &&
               lhs.theme == rhs.theme
    }
}
