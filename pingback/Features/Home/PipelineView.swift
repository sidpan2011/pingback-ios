import SwiftUI

struct PipelineView: View {
    @StateObject private var followUpStore = FollowUpStore.shared
    @State private var selectedTab = 0
    
    private var todayFollowUps: [FollowUp] {
        followUpStore.followUps.filter { $0.isToday && $0.status == .open }
    }
    
    private var overdueFollowUps: [FollowUp] {
        followUpStore.followUps.filter { $0.isOverdue }
    }
    
    private var upcomingFollowUps: [FollowUp] {
        followUpStore.followUps.filter { $0.isUpcoming }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    PipelineBucketView(
                        title: "Today",
                        followUps: todayFollowUps,
                        emptyMessage: "No follow-ups due today"
                    )
                    .tag(0)
                    
                    PipelineBucketView(
                        title: "Overdue",
                        followUps: overdueFollowUps,
                        emptyMessage: "No overdue follow-ups"
                    )
                    .tag(1)
                    
                    PipelineBucketView(
                        title: "Upcoming",
                        followUps: upcomingFollowUps,
                        emptyMessage: "No upcoming follow-ups"
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Pipeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Open add follow-up screen
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            followUpStore.loadFollowUps()
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabSelectorItem(
                title: "Today",
                count: todayFollowUps.count,
                isSelected: selectedTab == 0
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }
            
            TabSelectorItem(
                title: "Overdue",
                count: overdueFollowUps.count,
                isSelected: selectedTab == 1
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
            
            TabSelectorItem(
                title: "Upcoming",
                count: upcomingFollowUps.count,
                isSelected: selectedTab == 2
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 2
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
}

struct TabSelectorItem: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white : Color.secondary)
                            )
                    }
                }
                .foregroundColor(isSelected ? .white : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isSelected ? Color.blue : Color.clear)
                .cornerRadius(8)
        )
    }
}

struct PipelineBucketView: View {
    let title: String
    let followUps: [FollowUp]
    let emptyMessage: String
    
    var body: some View {
        Group {
            if followUps.isEmpty {
                emptyStateView
            } else {
                followUpsList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var followUpsList: some View {
        List {
            ForEach(followUps) { followUp in
                FollowUpRowView(followUp: followUp)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FollowUpRowView: View {
    let followUp: FollowUp
    @StateObject private var followUpStore = FollowUpStore.shared
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with contact and app
            HStack {
                // App icon
                Image(systemName: followUp.appType.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 24)
                
                // Contact name
                Text(followUp.person.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Due time
                Text(formatDueTime(followUp.dueAt))
                    .font(.caption)
                    .foregroundColor(followUp.isOverdue ? .red : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(followUp.isOverdue ? Color.red.opacity(0.1) : Color(.systemGray6))
                    )
            }
            
            // Note preview
            Text(followUp.note)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Action buttons
            HStack(spacing: 16) {
                ActionButton(title: "Open", icon: "message.circle.fill", color: .blue) {
                    openChat()
                }
                
                ActionButton(title: "Snooze", icon: "clock.circle.fill", color: .orange) {
                    snoozeFollowUp()
                }
                
                ActionButton(title: "Done", icon: "checkmark.circle.fill", color: .green) {
                    markAsDone()
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .contextMenu {
            Button("Open Chat", action: openChat)
            Button("Snooze 1 Day", action: snoozeFollowUp)
            Button("Mark as Done", action: markAsDone)
        }
    }
    
    private func formatDueTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func openChat() {
        let message = createMessage(for: followUp)
        let success = DeepLinkHelper.openChat(for: followUp, message: message)
        
        if success {
            AnalyticsService.shared.trackChatOpened(app: followUp.appType, source: "pipeline")
        }
    }
    
    private func snoozeFollowUp() {
        var updatedFollowUp = followUp
        updatedFollowUp.dueAt = Date().addingTimeInterval(24 * 60 * 60) // +24 hours
        updatedFollowUp.status = .snoozed
        
        followUpStore.updateFollowUp(updatedFollowUp)
        
        // Reschedule notification
        Task {
            do {
                try await NotificationService.shared.rescheduleNotification(for: updatedFollowUp)
            } catch {
                print("❌ Failed to reschedule notification: \(error)")
            }
        }
        
        AnalyticsService.shared.trackFollowUpSnoozed(followUpId: followUp.id, source: "pipeline")
    }
    
    private func markAsDone() {
        var updatedFollowUp = followUp
        updatedFollowUp.status = .done
        
        followUpStore.updateFollowUp(updatedFollowUp)
        
        // Cancel notification and handle cadence
        Task {
            await NotificationService.shared.cancelNotification(for: followUp.id)
            
            // If has cadence, schedule next occurrence
            if followUp.cadence != .none {
                await scheduleNextOccurrence()
            }
        }
        
        AnalyticsService.shared.trackFollowUpCompleted(
            followUpId: followUp.id,
            hadCadence: followUp.cadence != .none,
            source: "pipeline"
        )
    }
    
    private func scheduleNextOccurrence() async {
        guard followUp.cadence != .none else { return }
        
        let calendar = Calendar.current
        let nextDueDate: Date
        
        switch followUp.cadence {
        case .every7Days:
            nextDueDate = calendar.date(byAdding: .day, value: 7, to: followUp.dueAt) ?? followUp.dueAt
        case .every30Days:
            nextDueDate = calendar.date(byAdding: .day, value: 30, to: followUp.dueAt) ?? followUp.dueAt
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: followUp.dueAt) ?? followUp.dueAt
        case .none:
            return
        }
        
        let nextFollowUp = FollowUp(
            person: followUp.person,
            appType: followUp.appType,
            note: followUp.note,
            url: followUp.url,
            dueAt: nextDueDate,
            cadence: followUp.cadence,
            templateId: followUp.templateId
        )
        
        followUpStore.addFollowUp(nextFollowUp)
        
        do {
            try await NotificationService.shared.scheduleNotification(for: nextFollowUp)
        } catch {
            print("❌ Failed to schedule next occurrence: \(error)")
        }
    }
    
    private func createMessage(for followUp: FollowUp) -> String {
        // TODO: Use template system when implemented
        return followUp.note
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
        }
    }
}

#if DEBUG
#Preview {
    PipelineView()
}
#endif
