import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        List {
                Section("Getting Started") {
                    FAQItem(
                        question: "What is Pingback?",
                        answer: "Pingback is a follow-up management app that helps you track and manage your pending tasks and communications. It ensures you never miss an important follow-up again."
                    )
                    
                    FAQItem(
                        question: "How do I create a follow-up?",
                        answer: "Tap the '+' button on the home screen to create a new follow-up. Fill in the details like title, description, due date, and assign it to a person or task."
                    )
                    
                    FAQItem(
                        question: "What are the different tags?",
                        answer: "There are two main tags: 'Do' for tasks you need to complete, and 'Waiting-On' for tasks that depend on others. This helps you organize your follow-ups effectively."
                    )
                }
                
                Section("Managing Follow-ups") {
                    FAQItem(
                        question: "How do I mark a follow-up as completed?",
                        answer: "Swipe left on any follow-up in your list and tap 'Complete', or tap on the follow-up and use the complete button in the detail view."
                    )
                    
                    FAQItem(
                        question: "Can I snooze a follow-up?",
                        answer: "Yes! Swipe left on any follow-up and tap 'Snooze' to postpone it. You can choose how long to snooze it for (5 minutes to 1 hour) and when to be reminded."
                    )
                    
                    FAQItem(
                        question: "How do I edit a follow-up?",
                        answer: "Tap on any follow-up to open its detail view, then tap the edit button to modify the title, description, due date, or other details."
                    )
                }
                
                Section("Notifications") {
                    FAQItem(
                        question: "How do I enable notifications?",
                        answer: "Go to Settings > Notifications and toggle on 'Notifications'. You can also set your preferred reminder time and quiet hours."
                    )
                    
                    FAQItem(
                        question: "What types of notifications will I receive?",
                        answer: "You'll receive notifications for due date reminders, overdue alerts, and snooze reminders. You can customize which types you want to receive in the notification settings."
                    )
                    
                    FAQItem(
                        question: "Can I set quiet hours?",
                        answer: "Yes! In the notification settings, you can enable quiet hours to prevent notifications during specific times, like when you're sleeping."
                    )
                }
                
                Section("Data & Privacy") {
                    FAQItem(
                        question: "Is my data secure?",
                        answer: "Yes, we take your privacy seriously. All your data is stored locally on your device and is not shared with third parties without your explicit consent."
                    )
                    
                    FAQItem(
                        question: "Can I backup my data?",
                        answer: "Yes! Go to Settings > Backup & Export to create a backup of your follow-ups. You can also restore from a previous backup if needed."
                    )
                    
                    FAQItem(
                        question: "What happens if I delete the app?",
                        answer: "If you delete the app without creating a backup, your data will be lost. We recommend creating regular backups to prevent data loss."
                    )
                }
                
                Section("Troubleshooting") {
                    FAQItem(
                        question: "The app is running slowly. What should I do?",
                        answer: "Try closing and reopening the app, or restart your device. If the problem persists, try creating a backup and reinstalling the app."
                    )
                    
                    FAQItem(
                        question: "I'm not receiving notifications. What's wrong?",
                        answer: "Check that notifications are enabled in Settings > Notifications, and that your device's notification settings allow the app to send notifications."
                    )
                    
                    FAQItem(
                        question: "How do I contact support?",
                        answer: "You can contact support through the Help & Feedback section in Settings. We typically respond within 24 hours."
                    )
                }
        }
        .navigationTitle("FAQ & Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(primaryColor)
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FAQView()
}
