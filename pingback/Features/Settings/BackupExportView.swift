import SwiftUI

struct BackupExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var primaryColor: Color {
        themeManager.primaryColor
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Export Data") {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Follow-ups")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                Section("Backup") {
                    Button(action: {
                        createBackup()
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Create Backup")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                Section("Restore") {
                    Button(action: {
                        restoreBackup()
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("Restore from Backup")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Backup & Export")
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
    
    private func exportData() {
        // TODO: Implement data export functionality
        print("Export data tapped")
    }
    
    private func createBackup() {
        // TODO: Implement backup creation
        print("Create backup tapped")
    }
    
    private func restoreBackup() {
        // TODO: Implement backup restoration
        print("Restore backup tapped")
    }
}

#Preview {
    BackupExportView()
}
