import SwiftUI

struct AppLogoView: View {
    let app: AppType
    let size: CGFloat
    @State private var customImageExists = false
    
    init(_ app: AppType, size: CGFloat = 24) {
        self.app = app
        self.size = size
    }
    
    var body: some View {
        Group {
            if app.hasCustomLogo && customImageExists {
                // Use custom app logo
                Image(app.logoImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
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
        // Check if the custom image exists in the bundle
        if let _ = UIImage(named: app.logoImageName) {
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
