import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                featuresView
                footerView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // App Icon
            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Title and Subtitle
            VStack(spacing: 8) {
                Text("Welcome to Pro!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("You now have access to all premium features")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features View
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Pro Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(FeatureCatalog.proFeatureDescriptions.enumerated()), id: \.offset) { index, feature in
                    featureCard(feature: feature)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func featureCard(feature: ProFeatureDescription) -> some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Title and Description
            VStack(spacing: 4) {
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        VStack(spacing: 8) {
            Text("Thank you for being a Pro user!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Enjoy unlimited access to all Pingback features")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
}

#Preview {
    NavigationView {
        WhatsNewView()
    }
}
