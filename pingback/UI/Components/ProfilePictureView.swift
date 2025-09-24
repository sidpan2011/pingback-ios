import SwiftUI

struct ProfilePictureView: View {
    let profile: UserProfile?
    let size: CGFloat
    let showBorder: Bool
    
    init(profile: UserProfile?, size: CGFloat = 32, showBorder: Bool = false) {
        self.profile = profile
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        Group {
            if let avatarData = profile?.avatarData,
               let uiImage = UIImage(data: avatarData) {
                // Show custom avatar image
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Show initials as fallback
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(profile?.initials ?? "U")
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    )
            }
        }
        .overlay {
            // Optional border
            if showBorder {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    .frame(width: size, height: size)
            }
        }
    }
}

#Preview("With Avatar") {
    ProfilePictureView(
        profile: UserProfile(fullName: "John Doe", avatarData: nil),
        size: 40,
        showBorder: true
    )
}

#Preview("Without Profile") {
    ProfilePictureView(
        profile: nil,
        size: 32,
        showBorder: false
    )
}

#Preview("Large Size") {
    ProfilePictureView(
        profile: UserProfile(fullName: "Jane Smith", avatarData: nil),
        size: 64,
        showBorder: true
    )
}
