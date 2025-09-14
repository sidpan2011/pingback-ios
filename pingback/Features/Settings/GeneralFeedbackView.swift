import SwiftUI

struct GeneralFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var feedbackText = ""
    @State private var feedbackType = "General"
    @State private var hasChanges = false
    @State private var showingFeedbackSent = false
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    let feedbackTypes = ["General", "Appreciation", "Suggestion", "Complaint", "Other"]
    
    var body: some View {
        List {
                Section {
                    HStack {
                        Text("Feedback Type")
                        Spacer()
                        Picker("Type", selection: $feedbackType) {
                            ForEach(feedbackTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                } header: {
                    Text("What kind of feedback?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Feedback")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Share your thoughts")
                } footer: {
                    Text("We'd love to hear from you! Share your thoughts, suggestions, or any feedback you have about Pingback.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What we're looking for:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeedbackTip(icon: "star", text: "What you love about the app")
                            FeedbackTip(icon: "lightbulb", text: "Ideas for improvement")
                            FeedbackTip(icon: "heart", text: "Your overall experience")
                            FeedbackTip(icon: "message", text: "Any other thoughts or suggestions")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Help us improve")
                }
            }
            .navigationTitle("Share Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                
                if hasChanges {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Send") {
                            sendFeedback()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            .onChange(of: feedbackText) { _, _ in checkForChanges() }
            .onChange(of: feedbackType) { _, _ in checkForChanges() }
            .alert("Feedback Sent", isPresented: $showingFeedbackSent) {
                Button("OK") { }
            } message: {
                Text("Thank you for your feedback! We appreciate you taking the time to help us improve Pingback.")
            }
    }
    
    private func checkForChanges() {
        hasChanges = !feedbackText.isEmpty
    }
    
    private func sendFeedback() {
        // TODO: Send feedback to backend
        print("General feedback sent:")
        print("Type: \(feedbackType)")
        print("Feedback: \(feedbackText)")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingFeedbackSent = true
        dismiss()
    }
}

struct FeedbackTip: View {
    let icon: String
    let text: String
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(primaryColor)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    GeneralFeedbackView()
}
