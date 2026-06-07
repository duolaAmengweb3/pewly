import SwiftUI

struct OnboardingView: View {
    var done: () -> Void
    @State private var page = 0
    private let pages: [(symbol: String, title: String, body: String)] = [
        ("mic.fill", "Capture every sermon",
         "Tap once to record. Pewly transcribes the message and organizes it into points, scriptures and action items — so you never miss what was said."),
        ("book.closed.fill", "Scriptures, right there",
         "Every verse the preacher quotes is pulled in and linked to the full text — no flipping through your Bible to catch up."),
        ("checkmark.seal.fill", "Yours to keep, and to edit",
         "Fix anything the AI got wrong, keep your core notes free forever, and pay once — no weekly subscription, no surprise charges.")
    ]
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    let p = pages[i]
                    VStack(spacing: 24) {
                        Spacer()
                        if i == 0 {
                            Image("BrandMark").resizable().scaledToFit().frame(width: 132, height: 132)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                        } else {
                            ZStack {
                                Circle().fill(Theme.accentSoft).frame(width: 132, height: 132)
                                Image(systemName: p.symbol).font(.system(size: 50)).foregroundStyle(Theme.accent)
                            }
                        }
                        VStack(spacing: 12) {
                            Text(p.title).font(Theme.serif(28, .bold)).foregroundStyle(Theme.textHi).multilineTextAlignment(.center)
                            Text(p.body).font(.body).foregroundStyle(Theme.textMid).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 32)
                        }
                        Spacer(); Spacer()
                    }.tag(i)
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
            VStack(spacing: 12) {
                Button(page < pages.count - 1 ? "Continue" : "Start taking notes") {
                    if page < pages.count - 1 { withAnimation { page += 1 } } else { done() }
                }.buttonStyle(PrimaryButtonStyle())
                Text("Core notes free forever • No account needed • Pay once for AI")
                    .font(.caption).foregroundStyle(Theme.textLow).multilineTextAlignment(.center)
            }.padding(.horizontal, 20).padding(.bottom, 16)
        }
        .screenBackground()
    }
}
