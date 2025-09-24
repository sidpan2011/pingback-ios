import SwiftUI

struct SettingsSheetView: View {
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FollowUpStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingUpgrade = false
    @State private var showingSubscription = false
    @State private var showingSignOut = false
    @State private var showingCalendar = false
    @State private var showingDefaults = false
    @State private var showingTheme = false
    @State private var showingNotifications = false
    @State private var showingBackup = false
    @State private var showingHelp = false
    @State private var showingManageAccount = false
    @State private var showingRevenueCatDebug = false
    
    // Removed theme color overrides for instant theme switching
    
    var body: some View {
        NavigationView {
            List {
                
                // Account Section
                Section("Account") {
                    Button(action: { showingManageAccount = true }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Manage Account")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Red badge for incomplete profile
                            if userProfileStore.profile?.isProfileIncomplete ?? true {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Text("1")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    
                    Button(action: { showingUpgrade = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Upgrade to Pro")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    
                    Button(action: { showingSubscription = true }) {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Manage Subscription")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
                
                // Integrations Section
                // Section("Integrations") {
                //     Button(action: { showingCalendar = true }) {
                //         HStack {
                //             Image(systemName: "calendar")
                //                 .foregroundColor(.blue)
                //                 .frame(width: 24, height: 24)
                //             Text("Calendar")
                //                 .foregroundColor(.primary)
                //             Spacer()
                //             Image(systemName: "chevron.right")
                //                 .font(.system(size: 14, weight: .medium))
                //                 .foregroundColor(Color.secondary.opacity(0.6))
                //         }
                //         // .padding(.vertical, 8)
                //         .contentShape(Rectangle())
                //     }
                // }
                
                // Defaults Section
                Section("Defaults") {
                    Button(action: { showingDefaults = true }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Default Settings")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
                
                // Appearance Section - Commented out since theme syncs perfectly with system
                // Section("Appearance") {
                //     Button(action: { showingTheme = true }) {
                //         HStack {
                //             Image(systemName: "paintbrush")
                //                 .foregroundColor(.primary)
                //                 .frame(width: 24, height: 24)
                //             Text("Theme")
                //                 .foregroundColor(.primary)
                //             Spacer()
                //             Image(systemName: "chevron.right")
                //                 .font(.system(size: 14, weight: .medium))
                //                 .foregroundColor(Color.secondary.opacity(0.6))
                //         }
                //         // .padding(.vertical, 8)
                //         .contentShape(Rectangle())
                //     }
                // }
                
                // Notifications Section
                Section("Notifications") {
                    Button(action: { showingNotifications = true }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Notifications")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
                
                // Data Section
                // Section("Data") {
                //     Button(action: { showingBackup = true }) {
                //         HStack {
                //             Image(systemName: "square.and.arrow.up")
                //                 .foregroundColor(.blue)
                //                 .frame(width: 24, height: 24)
                //             Text("Backup / Export")
                //                 .foregroundColor(.primary)
                //             Spacer()
                //             Image(systemName: "chevron.right")
                //                 .font(.system(size: 14, weight: .medium))
                //                 .foregroundColor(Color.secondary.opacity(0.6))
                //         }
                //         // .padding(.vertical, 8)
                //         .contentShape(Rectangle())
                //     }
                // }
                
                // Help Section
                Section("Help") {
                    Button(action: { showingHelp = true }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Help & Feedback")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section("Debug") {
                    Button(action: { showingRevenueCatDebug = true }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("RevenueCat Debug")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                        .contentShape(Rectangle())
                    }
                }
                #endif
                
                // Logout Section
                // TODO: Uncomment when sign out functionality is ready
                /*
                Section {
                    Button(action: { showingSignOut = true }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        // .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                }
                */
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                HybridPaywallView()
            }
            .sheet(isPresented: $showingSubscription) {
                NavigationView {
                    RevenueCatSubscriptionView()
                }
            }
            // TODO: Uncomment when sign out functionality is ready
            /*
            .sheet(isPresented: $showingSignOut) {
                SignOutView()
            }
            */
            .sheet(isPresented: $showingCalendar) {
                CalendarIntegrationView()
            }
            .sheet(isPresented: $showingDefaults) {
                NavigationView {
                    DefaultsView()
                        .environmentObject(themeManager)
                }
            }
            // Theme sheet commented out since theme syncs perfectly with system
            // .sheet(isPresented: $showingTheme) {
            //     NavigationView {
            //         ThemeView()
            //             .environmentObject(themeManager)
            //     }
            // }
            .sheet(isPresented: $showingNotifications) {
                NavigationView {
                    NotificationsView()
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $showingBackup) {
                NavigationView {
                    BackupExportView()
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $showingHelp) {
                NavigationView {
                    HelpFeedbackView()
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $showingManageAccount) {
                NavigationView {
                    ManageAccountView()
                        .environmentObject(themeManager)
                        .environmentObject(userProfileStore)
                }
            }
            .sheet(isPresented: $showingRevenueCatDebug) {
                RevenueCatDebugView()
            }
        }
    }
}


           #Preview {
               SettingsSheetView()
                   .environmentObject(ThemeManager.shared)
                   .environmentObject(FollowUpStore())
           }
