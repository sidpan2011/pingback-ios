import Foundation

extension Date {
    func relativeDescription() -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: .now)
    }
}


