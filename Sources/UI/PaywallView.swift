import SwiftUI

/// Buyout-primary,踩头部订阅墙. Real wedge: every competitor locks AI behind subscription / caps free.
struct PaywallView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    private let perks: [(String, String)] = [
        ("infinity", "Unlimited AI sermon organizing"),
        ("pencil", "Edit anything the AI got wrong"),
        ("book.fill", "Auto scripture index — full text inline"),
        ("arrow.triangle.2.circlepath", "Sync across your devices"),
        ("square.and.arrow.up", "Export & share with your church/family")
    ]
    var body: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textMid).padding(8) } }.padding(.horizontal, 12).padding(.top, 8)
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        ZStack { Circle().fill(Theme.accentSoft).frame(width: 84, height: 84); Image(systemName: "checkmark.seal.fill").font(.system(size: 34)).foregroundStyle(Theme.accent) }
                        Text("Pewly Pro").font(Theme.serif(26, .bold)).foregroundStyle(Theme.textHi)
                        Text("Unlock AI — keep it forever.").font(.subheadline).foregroundStyle(Theme.textMid)
                    }.padding(.top, 4)
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(perks, id: \.1) { p in
                            HStack(spacing: 12) { Image(systemName: p.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.accent).frame(width: 26); Text(p.1).font(.system(size: 15)).foregroundStyle(Theme.textHi); Spacer() }
                        }
                    }.card(padding: 18)
                    // 诚实定价对比
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill").font(.caption).foregroundStyle(Theme.success)
                        Text("Other sermon apps charge weekly or monthly forever, or cap you at 5 notes. Pewly: your core notes stay free, and Pro is a one-time purchase — no subscription, no surprise charges.")
                            .font(.system(size: 12)).foregroundStyle(Theme.textMid).lineSpacing(2)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(16).padding(.bottom, 110)
            }
        }
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    Task { if await pro.purchase() { dismiss() } }
                } label: {
                    if pro.purchasing { ProgressView().tint(.white) }
                    else { Text("Unlock Pewly Pro — \(pro.priceText) once") }
                }.buttonStyle(PrimaryButtonStyle()).disabled(pro.purchasing)
                HStack(spacing: 16) {
                    Button("Restore") { Task { await pro.restore(); if pro.isPro { dismiss() } } }
                    Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Privacy", destination: URL(string: "https://duolaamengweb3.github.io/pewly/privacy.html")!)
                }.font(.caption).foregroundStyle(Theme.textLow)
            }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8).background(Theme.canvas)
        }
    }
}
