import SwiftUI

struct QuickChip: View {
    var label: String
    var action: () -> Void
    init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    var body: some View {
        Button(label, action: action)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary)
            .clipShape(Capsule())
    }
}


