import SwiftUI

struct HelpFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    // Removed themeManager dependency for instant theme switching
    @State private var showingFAQ = false
    @State private var showingAbout = false
    @State private var showingBugReport = false
    @State private var showingFeatureRequest = false
    @State private var showingGeneralFeedback = false
    
    // Use native SwiftUI colors for instant theme switching
    
    var body: some View {
        List {
                Section("Help") {
                    Button(action: {
                        showingFAQ = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.primary)
                            Text("FAQ & Help Center")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.primary)
                            Text("About")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                    
                    Button(action: {
                        contactSupport()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.primary)
                            Text("Contact Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                }
                
                Section("Feedback") {
                    Button(action: {
                        showingBugReport = true
                    }) {
                        HStack {
                            Image(systemName: "ant")
                                .foregroundColor(.primary)
                            Text("Report a Bug")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                    
                    Button(action: {
                        showingFeatureRequest = true
                    }) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.primary)
                            Text("Suggest a Feature")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                    
                    Button(action: {
                        showingGeneralFeedback = true
                    }) {
                        HStack {
                            Image(systemName: "message")
                                .foregroundColor(.primary)
                            Text("Share Feedback")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        rateApp()
                    }) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.primary)
                            Text("Rate App")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary.opacity(0.6))
                        }
                    }
                }
        }
        .navigationTitle("Help & Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingBugReport) {
                BugReportView()
            }
            .sheet(isPresented: $showingFeatureRequest) {
                FeatureRequestView()
            }
            .sheet(isPresented: $showingGeneralFeedback) {
                GeneralFeedbackView()
            }
    }
    
    private func contactSupport() {
        // TODO: Open support contact
        print("Contact support tapped")
    }
    
    private func rateApp() {
        // TODO: Open App Store rating
        print("Rate app tapped")
    }
}

#Preview {
    HelpFeedbackView()
        .environmentObject(ThemeManager.shared)
}
