import Foundation

extension String {
    func containsAny(of needles: [String]) -> Bool {
        for n in needles where self.contains(n) { return true }
        return false
    }
    func containsWord(_ word: String) -> Bool {
        let surrounded = " " + self + " "
        return surrounded.contains(" \(word) ")
    }
}


