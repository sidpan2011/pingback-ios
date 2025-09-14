import SwiftUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var bugDescription = ""
    @State private var stepsToReproduce = ""
    @State private var expectedBehavior = ""
    @State private var actualBehavior = ""
    @State private var deviceInfo = ""
    @State private var hasChanges = false
    @State private var showingBugReportSent = false
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bug Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $bugDescription)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What's the bug?")
                } footer: {
                    Text("Please describe the bug you encountered in detail.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps to Reproduce")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $stepsToReproduce)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("How can we reproduce it?")
                } footer: {
                    Text("List the steps you took that led to the bug.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expected Behavior")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $expectedBehavior)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What should have happened?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Actual Behavior")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $actualBehavior)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What actually happened?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $deviceInfo)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Device Details")
                } footer: {
                    Text("Include your device model, iOS version, and any other relevant details.")
                }
            }
            .navigationTitle("Report a Bug")
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
                            sendBugReport()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            .onChange(of: bugDescription) { _, _ in checkForChanges() }
            .onChange(of: stepsToReproduce) { _, _ in checkForChanges() }
            .onChange(of: expectedBehavior) { _, _ in checkForChanges() }
            .onChange(of: actualBehavior) { _, _ in checkForChanges() }
            .onChange(of: deviceInfo) { _, _ in checkForChanges() }
            .alert("Bug Report Sent", isPresented: $showingBugReportSent) {
                Button("OK") { }
            } message: {
                Text("Thank you for reporting this bug! We'll investigate and get back to you with a fix.")
            }
    }
    
    private func checkForChanges() {
        hasChanges = !bugDescription.isEmpty || !stepsToReproduce.isEmpty || 
                    !expectedBehavior.isEmpty || !actualBehavior.isEmpty || !deviceInfo.isEmpty
    }
    
    private func sendBugReport() {
        // TODO: Send bug report to backend
        print("Bug report sent:")
        print("Description: \(bugDescription)")
        print("Steps: \(stepsToReproduce)")
        print("Expected: \(expectedBehavior)")
        print("Actual: \(actualBehavior)")
        print("Device: \(deviceInfo)")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingBugReportSent = true
        dismiss()
    }
}


#Preview {
    BugReportView()
        .environmentObject(ThemeManager.shared)
}
