import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button { if !store.isPro { showPaywall = true } } label: {
                        HStack(spacing: 14) {
                            Image(systemName: store.isPro ? "checkmark.seal.fill" : "checkmark.seal").font(.system(size: 20)).foregroundStyle(Theme.accent).frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.isPro ? "Pewly Pro" : "Unlock Pewly Pro").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textHi)
                                Text(store.isPro ? "Thank you — unlocked forever" : "AI organizing, sync & export · one-time").font(.system(size: 13)).foregroundStyle(Theme.textMid)
                            }
                            Spacer()
                            if !store.isPro { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textLow) }
                        }.card(padding: 16)
                    }.buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Our promise")
                        promise("checkmark.shield", "Your core notes stay free forever — never locked.")
                        promise("dollarsign.circle", "Pro is a one-time purchase. No subscription, no surprise charges.")
                        promise("book", "Scripture text is public-domain (KJV/WEB). Your notes stay private on your device.")
                    }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 18)

                    VStack(spacing: 0) {
                        row("textformat.size", "Bible translation")
                        Divider().overlay(Theme.hairline)
                        row("star", "Rate Pewly")
                        Divider().overlay(Theme.hairline)
                        row("envelope", "Contact support")
                        Divider().overlay(Theme.hairline)
                        row("hand.raised", "Privacy policy")
                    }.card(padding: 4)
                    Text("Pewly 1.0").font(.caption2).foregroundStyle(Theme.textLow)
                }.padding(16)
            }
            .screenBackground().navigationTitle("Settings").toolbarBackground(Theme.canvas, for: .navigationBar)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
    private func promise(_ icon: String, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 12) { Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent).frame(width: 24); Text(t).font(.system(size: 14)).foregroundStyle(Theme.textMid).lineSpacing(2); Spacer() }
    }
    private func row(_ icon: String, _ t: String) -> some View {
        HStack(spacing: 12) { Image(systemName: icon).font(.system(size: 15)).foregroundStyle(Theme.textMid).frame(width: 26); Text(t).font(.system(size: 15)).foregroundStyle(Theme.textHi); Spacer(); Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textLow) }
            .padding(.horizontal, 12).padding(.vertical, 14).contentShape(Rectangle())
    }
}
