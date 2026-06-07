import SwiftUI

@main
struct PewlyApp: App {
    @StateObject private var store = Store()
    @StateObject private var pro = ProStore()
    @AppStorage("pewly.onboarded") private var onboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || ProcessInfo.processInfo.arguments.contains("-skipOnboard") {
                    RootView()
                } else {
                    OnboardingView { onboarded = true }
                }
            }
            .environmentObject(store)
            .environmentObject(pro)
            .preferredColorScheme(.light)   // 暖白纸感,不做深色
            .tint(Theme.accent)
            .task { await pro.load(); store.isPro = pro.isPro }
            .onChange(of: pro.isPro) { _, v in store.isPro = v }
        }
    }
}
