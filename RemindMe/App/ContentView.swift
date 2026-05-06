import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = !UserPreferences.load().hasCompletedOnboarding

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                TabBarView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
    }
}
