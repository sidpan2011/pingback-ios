import SwiftUI
import PhotosUI

struct ManageAccountView: View {
    @StateObject private var userProfileStore = UserProfileStore()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    @State private var hasChanges = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    
    // Theme-aware colors
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    private var secondaryColor: Color {
        themeManager.secondaryColor
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Picture Section - Inside Form with custom styling
                Section {
                    VStack(spacing: 16) {
                        // Avatar with edit button
                        ZStack {
                            if let avatarData = userProfileStore.profile?.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                // Initials placeholder
                                Circle()
                                    .fill(Color.blue.gradient)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(userProfileStore.profile?.initials ?? "U")
                                            .font(.system(size: 40, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                        }
                        .accessibilityLabel("Profile picture")
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            showingPhotoPicker = true
                        }
                        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    try? await userProfileStore.updateAvatar(data)
                                    await MainActor.run {
                                        hasChanges = true
                                    }
                                }
                            }
                        }
                        
                        Text("Tap to change profile picture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
                Section("Account Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        if isEditing {
                            TextField("Enter your full name", text: $fullName)
                                .onChange(of: fullName) { _, _ in
                                    checkForChanges()
                                }
                        } else {
                            Text(fullName.isEmpty ? "Not set" : fullName)
                                .foregroundColor(fullName.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        if isEditing {
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) { _, _ in
                                    checkForChanges()
                                }
                        } else {
                            Text(email.isEmpty ? "Not set" : email)
                                .foregroundColor(email.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                }
                
                if !isEditing {
                    Section {
                        Button(action: {
                            isEditing = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Edit Account")
                                    .font(.body)
                                    // .fontWeight(.medium)
                                    .foregroundColor(primaryColor)
                                Spacer()
                            }
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button(action: {
                            cancelEditing()
                        }) {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                    .font(.body)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Account")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Manage Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isEditing && hasChanges {
                            showingDeleteAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .foregroundColor(primaryColor)
                        .disabled(!hasChanges)
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
            .onChange(of: userProfileStore.profile) { _, _ in
                loadUserData()
            }
            .alert("Discard Changes?", isPresented: $showingDeleteAlert) {
                Button("Discard", role: .destructive) {
                    isEditing = false
                    loadUserData()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.")
            }
        }
    }
    
    private func loadUserData() {
        print("🔄 ManageAccountView: Loading user data from store")
        print("   - Profile exists: \(userProfileStore.profile != nil)")
        print("   - Full Name: '\(userProfileStore.profile?.fullName ?? "nil")'")
        print("   - Email: '\(userProfileStore.profile?.email ?? "nil")'")
        
        fullName = userProfileStore.profile?.fullName ?? ""
        email = userProfileStore.profile?.email ?? ""
        
        print("✅ ManageAccountView: Data loaded into fields")
        print("   - fullName field: '\(fullName)'")
        print("   - email field: '\(email)'")
    }
    
    private func checkForChanges() {
        hasChanges = fullName != (userProfileStore.profile?.fullName ?? "") ||
                    email != (userProfileStore.profile?.email ?? "")
    }
    
    private func saveChanges() {
        Task {
            do {
                // Create or update profile
                let profile = UserProfile(
                    fullName: fullName,
                    email: email.isEmpty ? nil : email,
                    avatarData: userProfileStore.profile?.avatarData,
                    theme: userProfileStore.profile?.theme ?? "system"
                )
                
                try await userProfileStore.saveProfile(profile)
                
                await MainActor.run {
                    isEditing = false
                    hasChanges = false
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } catch {
                print("Failed to save profile: \(error)")
            }
        }
    }
    
    private func cancelEditing() {
        loadUserData()
        isEditing = false
        hasChanges = false
    }
    
    private func deleteAccount() {
        // TODO: Implement actual account deletion logic
        // This would typically involve:
        // 1. Calling a backend API to delete the account
        // 2. Clearing local data
        // 3. Signing out the user
        // 4. Navigating back to login/signup screen
        
        // For now, just show a placeholder implementation
        print("Account deletion requested")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Dismiss the view
        dismiss()
    }
}

#Preview {
    ManageAccountView()
}
