import SwiftUI

struct DueBadge: View {
    let date: Date
    let status: Status
    
    var body: some View {
        let rel = date.relativeDescription()
        let color: Color = date < .now ? .red : .orange
        
        HStack(spacing: 4) {
            // Show snooze icon if the item is snoozed
            if status == .snoozed {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
            }
            
            Text(rel)
                .font(.system(size: 14))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        // .background(color.opacity(0.15))
        // .clipShape(Capsule())
    }
}


