import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentStep = 0
    
    private let steps = [
        OnboardingStep(
            icon: "bell.fill",
            title: "Never Miss a Follow-up",
            description: "Stay on top of your important conversations and commitments with smart reminders."
        ),
        OnboardingStep(
            icon: "clock.arrow.circlepath",
            title: "Snooze & Reschedule",
            description: "Life gets busy. Easily snooze follow-ups and reschedule them for when you're ready."
        ),
        OnboardingStep(
            icon: "app.connected.to.app.below.fill",
            title: "Connect Your Apps",
            description: "Seamlessly integrate with WhatsApp, Telegram, Email, SMS, and Instagram."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 20)
                
                // Carousel content
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        OnboardingStepView(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Bottom buttons
                VStack(spacing: 16) {
                    if currentStep < steps.count - 1 {
                        // Next button
                        Button(action: {
                            withAnimation(.easeInOut) {
                                currentStep += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(scheme == .dark ? Color.black : Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(scheme == .dark ? Color.white : Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Skip button
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Final "Let's Go" button
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Let's Go!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(scheme == .dark ? Color.black : Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(scheme == .dark ? Color.white : Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: step.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.primary)
            
            // Content
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}


