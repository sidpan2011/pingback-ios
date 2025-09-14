import SwiftUI

struct DueBadge: View {
    let date: Date
    
    var body: some View {
        let rel = date.relativeDescription()
        let color: Color = date < .now ? .red : .orange
        return Text(rel)
            .font(.system(size: 14))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            // .background(color.opacity(0.15))
            .foregroundStyle(color)
            // .clipShape(Capsule())
    }
}


