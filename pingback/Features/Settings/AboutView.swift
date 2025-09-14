import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    // Removed themeManager dependency for instant theme switching
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        if let appIcon = UIImage(named: "AppIcon") {
                            Image(uiImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            // Fallback if app icon is not found
                            Image(systemName: "app.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.primary)
                                .frame(width: 120, height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                        
                        VStack(spacing: 4) {
                            Text("Pingback")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Follow-up Management")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Version Info
                    VStack(spacing: 8) {
                        Text("Version 1.0.0")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Text("Build 1")
                        //     .font(.caption)
                        //     .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Pingback")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Pingback is designed to help you stay on top of your follow-ups and never miss an important task or communication. Whether you're waiting for a response from a colleague, following up on a project, or tracking personal tasks, Pingback keeps everything organized and ensures nothing falls through the cracks.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Features")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AboutFeatureRow(icon: "checkmark.circle", text: "Smart follow-up tracking")
                            AboutFeatureRow(icon: "bell", text: "Customizable notifications")
                            AboutFeatureRow(icon: "tag", text: "Organized with tags")
                            AboutFeatureRow(icon: "moon", text: "Snooze functionality")
                            AboutFeatureRow(icon: "icloud", text: "Backup and restore")
                            AboutFeatureRow(icon: "paintbrush", text: "Dark and light themes")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Developer Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Developer")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Pingback is developed with ❤️ to help you stay organized and productive. We're constantly working to improve the app based on user feedback.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // Legal
                    // VStack(alignment: .leading, spacing: 12) {
                    //     Text("Legal")
                    //         .font(.headline)
                    //         .foregroundColor(.primary)
                        
                    //     VStack(alignment: .leading, spacing: 8) {
                    //         Text("Privacy Policy")
                    //             .font(.body)
                    //             .foregroundColor(.blue)
                    //             .onTapGesture {
                    //                 // TODO: Open privacy policy
                    //             }
                            
                    //         Text("Terms of Service")
                    //             .font(.body)
                    //             .foregroundColor(.blue)
                    //             .onTapGesture {
                    //                 // TODO: Open terms of service
                    //             }
                    //     }
                    // }
                    // .padding(.horizontal)
                    
                    // Spacer(minLength: 20)
                }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    // Removed themeManager dependency for instant theme switching
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    AboutView()
}
