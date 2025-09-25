import SwiftUI

struct PostBumpSheet: View {
    let followUp: FollowUp
    let onDone: () -> Void
    let onSnooze: (TimeInterval) -> Void
    let onKeepOpen: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("Chat Opened!")
                        .font(.title2.bold())
                    
                    Text("What would you like to do with this follow-up?")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Follow-up info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AppLogoView(followUp.appType, size: 24)
                        Text(followUp.person.displayName)
                            .font(.headline)
                        Spacer()
                    }
                    
                    if !followUp.note.isEmpty {
                        Text(followUp.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Action buttons
                VStack(spacing: 12) {
                    if followUp.cadence != .none && subscriptionManager.isPro {
                        // If has cadence and user is Pro, offer Done & reschedule
                        Button {
                            onDone()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Done & Reschedule")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                    Text("Next: \(nextCadenceDate())")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(.green)
                            .cornerRadius(12)
                        }
                    } else {
                        // No cadence or not Pro, just mark done
                        Button {
                            onDone()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                Text("Mark Done")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding()
                            .background(.green)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Snooze options (Pro only)
                    if subscriptionManager.isPro {
                        Menu {
                            Button("1 hour") {
                                onSnooze(3600)
                                dismiss()
                            }
                            Button("Tonight 6 PM") {
                                let tonightSix = Calendar.current.dateInterval(of: .day, for: Date())?.start
                                    .addingTimeInterval(18 * 3600) ?? Date().addingTimeInterval(3600)
                                onSnooze(tonightSix.timeIntervalSince(Date()))
                                dismiss()
                            }
                            Button("Tomorrow 9 AM") {
                                let tomorrowNine = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                    .flatMap { Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: $0) }
                                    ?? Date().addingTimeInterval(24 * 3600)
                                onSnooze(tomorrowNine.timeIntervalSince(Date()))
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.orange)
                                Text("Snooze")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding()
                            .background(.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    } else {
                        // Free users get basic snooze (1 hour only)
                        Button {
                            onSnooze(3600) // 1 hour only
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.orange)
                                Text("Snooze 1 Hour")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                            .padding()
                            .background(.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Keep open
                    Button {
                        onKeepOpen()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.blue)
                            Text("Keep Open")
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        .padding()
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            // .navigationTitle("Follow-up Sent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func nextCadenceDate() -> String {
        let calendar = Calendar.current
        let nextDate: Date
        
        switch followUp.cadence {
        case .every7Days:
            nextDate = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        case .every30Days:
            nextDate = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case .none:
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextDate)
    }
}

#Preview {
    PostBumpSheet(
        followUp: FollowUp(
            person: Person(firstName: "John", lastName: "Doe", phoneNumbers: ["+1234567890"]),
            appType: .whatsapp,
            note: "Follow up about the project",
            dueAt: Date(),
            cadence: .every7Days
        ),
        onDone: {},
        onSnooze: { _ in },
        onKeepOpen: {}
    )
}
