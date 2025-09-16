import SwiftUI

struct AppLogoView: View {
    let app: AppKind
    let size: CGFloat
    @State private var customImageExists = false
    
    init(_ app: AppKind, size: CGFloat = 24) {
        self.app = app
        self.size = size
    }
    
    var body: some View {
        Group {
            if app.hasCustomLogo && customImageExists {
                // Use custom app logo - try to load from main app bundle first
                let bundleUrl = Bundle.main.bundleURL.appendingPathComponent("../../").standardized
                if let containerBundle = Bundle(url: bundleUrl.appendingPathComponent("pingback.app")),
                   let uiImage = UIImage(named: app.logoImageName, in: containerBundle, compatibleWith: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                } else {
                    // Fallback to current bundle
                    Image(app.logoImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                }
            } else {
                // Fallback to SF Symbol
                Image(systemName: app.icon)
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(.blue)
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            checkIfCustomImageExists()
        }
    }
    
    private func checkIfCustomImageExists() {
        // Try to load the image from the main app's bundle
        // In share extensions, we need to look in the container app's bundle
        let bundleUrl = Bundle.main.bundleURL.appendingPathComponent("../../").standardized
        
        // Check if image exists in the container bundle first
        if let containerBundle = Bundle(url: bundleUrl.appendingPathComponent("pingback.app")),
           let _ = UIImage(named: app.logoImageName, in: containerBundle, compatibleWith: nil) {
            customImageExists = true
        } else if let _ = UIImage(named: app.logoImageName) {
            customImageExists = true
        } else {
            customImageExists = false
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            AppLogoView(.whatsapp, size: 32)
            AppLogoView(.telegram, size: 32)
            AppLogoView(.sms, size: 32)
            AppLogoView(.slack, size: 32)
        }
        
        Text("App Logos (32pt)")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        HStack(spacing: 16) {
            AppLogoView(.whatsapp, size: 24)
            AppLogoView(.telegram, size: 24)
            AppLogoView(.sms, size: 24)
            AppLogoView(.slack, size: 24)
        }
        
        Text("App Logos (24pt)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
