import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(.tint)
            }
        }
    }
}


