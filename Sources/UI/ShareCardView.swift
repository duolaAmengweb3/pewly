import SwiftUI

/// Shareable sermon/verse card — differentiation 4.3.2 + a free distribution channel.
struct ShareCardView: View {
    let note: SermonNote
    @Environment(\.dismiss) private var dismiss

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("PEWLY").font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(Theme.accent)
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.accent)
            }
            Text(note.title).font(Theme.serif(26, .bold)).foregroundStyle(Theme.textHi)
            if let v = note.verses.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text(v.ref).font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(Theme.gold)
                    Text(VerseText.text(for: v.ref)).font(.system(size: 18, design: .serif)).foregroundStyle(Theme.textHi).lineSpacing(6)
                }.padding(16).background(Theme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            if let p = note.points.first {
                Text("“\(p)”").font(.system(size: 15)).foregroundStyle(Theme.textMid).italic()
            }
            Text("\(note.speaker) • \(note.date.formatted(.dateTime.month().day().year()))").font(.system(size: 12)).foregroundStyle(Theme.textLow)
        }
        .padding(24)
        .frame(width: 320)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    @MainActor private func rendered() -> Image {
        let r = ImageRenderer(content: card.padding(20).background(Theme.canvas))
        r.scale = 3
        return r.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "photo")
    }

    private var exportText: String {
        var s = [note.title, "\(note.speaker) — \(note.date.formatted(.dateTime.month().day().year()))"]
        if !note.verses.isEmpty { s.append("\nScriptures:"); note.verses.forEach { s.append("  \($0.ref)") } }
        if !note.points.isEmpty { s.append("\nKey points:"); note.points.forEach { s.append("  • \($0)") } }
        if !note.reflection.isEmpty { s.append("\nReflection: \(note.reflection)") }
        if !note.prayerItems.isEmpty { s.append("\nPrayer:"); note.prayerItems.forEach { s.append("  • \($0)") } }
        if !note.actions.isEmpty { s.append("\nTo do:"); note.actions.forEach { s.append("  - \($0.text)") } }
        s.append("\n— via Pewly")
        return s.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Theme.hairline).frame(width: 36, height: 5).padding(.top, 8)
            ScrollView { card.padding(.vertical, 8) }
            VStack(spacing: 10) {
                ShareLink(item: rendered(), preview: SharePreview(note.title, image: rendered())) {
                    Label("Share verse card", systemImage: "photo").fontWeight(.semibold)
                }.buttonStyle(PrimaryButtonStyle())
                ShareLink(item: exportText) {
                    Label("Export as text", systemImage: "doc.text").fontWeight(.semibold)
                }.buttonStyle(SecondaryButtonStyle())
            }.padding(.horizontal, 20).padding(.bottom, 16)
        }.screenBackground()
    }
}
