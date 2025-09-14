import SwiftUI

struct AppLogoView: View {
    let app: AppKind
    let size: CGFloat
    
    init(_ app: AppKind, size: CGFloat = 24) {
        self.app = app
        self.size = size
    }
    
    var body: some View {
        Group {
            if app.hasCustomLogo {
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
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            AppLogoView(.whatsapp, size: 32)
            AppLogoView(.telegram, size: 32)
            AppLogoView(.email, size: 32)
            AppLogoView(.sms, size: 32)
            AppLogoView(.other, size: 32)
        }
        
        Text("App Logos (32pt)")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        HStack(spacing: 16) {
            AppLogoView(.whatsapp, size: 24)
            AppLogoView(.telegram, size: 24)
            AppLogoView(.email, size: 24)
            AppLogoView(.sms, size: 24)
            AppLogoView(.other, size: 24)
        }
        
        Text("App Logos (24pt)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
