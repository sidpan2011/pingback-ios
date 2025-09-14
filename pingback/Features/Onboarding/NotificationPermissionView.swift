import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequesting = false
    @State private var permissionGranted = false
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "bell.badge")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 16) {
                Text("Stay on Top of Your Follow-ups")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get timely reminders so you never miss an important follow-up. You can customize notification settings anytime.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                // Benefits
                NotificationBenefitRow(
                    icon: "clock",
                    title: "Due Date Reminders",
                    description: "Get notified when follow-ups are due"
                )
                
                NotificationBenefitRow(
                    icon: "exclamationmark.triangle",
                    title: "Overdue Alerts",
                    description: "Never miss important tasks"
                )
                
                NotificationBenefitRow(
                    icon: "moon.zzz",
                    title: "Quiet Hours",
                    description: "Respect your sleep and focus time"
                )
                
                NotificationBenefitRow(
                    icon: "hand.tap",
                    title: "Quick Actions",
                    description: "Snooze or mark done from notifications"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: requestPermission) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isRequesting ? "Requesting..." : "Enable Notifications")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)
                
                Button("Maybe Later") {
                    onComplete(false)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        .task {
            await checkCurrentStatus()
        }
    }
    
    private func checkCurrentStatus() async {
        await notificationManager.checkAuthorizationStatus()
        if notificationManager.authorizationStatus == .authorized {
            permissionGranted = true
            onComplete(true)
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        
        Task {
            let granted = await notificationManager.requestPermission()
            
            await MainActor.run {
                isRequesting = false
                permissionGranted = granted
                
                // Small delay to show the result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete(granted)
                }
            }
        }
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationPermissionView { granted in
        print("Permission granted: \(granted)")
    }
}
