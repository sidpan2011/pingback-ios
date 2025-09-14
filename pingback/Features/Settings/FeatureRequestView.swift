import SwiftUI

struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var featureTitle = ""
    @State private var featureDescription = ""
    @State private var useCase = ""
    @State private var priority = "Medium"
    @State private var hasChanges = false
    @State private var showingFeatureRequestSent = false
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    let priorityOptions = ["Low", "Medium", "High"]
    
    var body: some View {
        List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feature Title")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Brief title for your feature request", text: $featureTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What feature would you like?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feature Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $featureDescription)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Describe the feature")
                } footer: {
                    Text("Please provide a detailed description of how the feature should work.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use Case")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $useCase)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("How would you use this feature?")
                } footer: {
                    Text("Explain how this feature would help you or improve your workflow.")
                }
                
                Section {
                    HStack {
                        Text("Priority")
                        Spacer()
                        Picker("Priority", selection: $priority) {
                            ForEach(priorityOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(primaryColor)
                    }
                } header: {
                    Text("Priority Level")
                } footer: {
                    Text("How important is this feature to you?")
                }
            }
            .navigationTitle("Suggest a Feature")
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
                            sendFeatureRequest()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                    }
                }
            }
            .onChange(of: featureTitle) { _, _ in checkForChanges() }
            .onChange(of: featureDescription) { _, _ in checkForChanges() }
            .onChange(of: useCase) { _, _ in checkForChanges() }
            .onChange(of: priority) { _, _ in checkForChanges() }
            .alert("Feature Request Sent", isPresented: $showingFeatureRequestSent) {
                Button("OK") { }
            } message: {
                Text("Thank you for your suggestion! We'll review it and consider it for future updates.")
            }
    }
    
    private func checkForChanges() {
        hasChanges = !featureTitle.isEmpty || !featureDescription.isEmpty || !useCase.isEmpty
    }
    
    private func sendFeatureRequest() {
        // TODO: Send feature request to backend
        print("Feature request sent:")
        print("Title: \(featureTitle)")
        print("Description: \(featureDescription)")
        print("Use Case: \(useCase)")
        print("Priority: \(priority)")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingFeatureRequestSent = true
        dismiss()
    }
}

#Preview {
    FeatureRequestView()
}
