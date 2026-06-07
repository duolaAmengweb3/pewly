import SwiftUI

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased()).font(.system(size: 12, weight: .semibold)).tracking(1).foregroundStyle(Theme.textLow)
    }
}

struct KindTag: View {
    let kind: NoteKind
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.symbol).font(.system(size: 9))
            Text(kind.rawValue).font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Theme.accentSoft, in: Capsule())
    }
}

struct NoteCard: View {
    let note: SermonNote
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title).font(Theme.serif(18, .semibold)).foregroundStyle(Theme.textHi).lineLimit(2)
                Spacer()
                if note.aiGenerated { Image(systemName: "sparkles").font(.caption).foregroundStyle(Theme.gold) }
            }
            Text("\(note.speaker) • \(note.date.formatted(.dateTime.month().day())) • \(note.durationMin)min")
                .font(.system(size: 12)).foregroundStyle(Theme.textMid)
            HStack(spacing: 6) {
                KindTag(kind: note.kind)
                if !note.verses.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "book").font(.system(size: 9))
                        Text("\(note.verses.count) verse\(note.verses.count == 1 ? "" : "s")").font(.system(size: 11, weight: .medium))
                    }.foregroundStyle(Theme.gold).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.gold.opacity(0.12), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
    }
}

/// Public-domain verse text (KJV/WEB). Today a small sample; real fill = bible-api / bundled JSON.
enum VerseText {
    static let sample: [String: String] = [
        "John 3:16": "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
        "Galatians 5:22-23": "But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance: against such there is no law.",
        "John 15:5": "I am the vine, ye are the branches: He that abideth in me, and I in him, the same bringeth forth much fruit: for without me ye can do nothing.",
        "Proverbs 3:5-6": "Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.",
        "James 1:5": "If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.",
        "2 Peter 3:18": "But grow in grace, and in the knowledge of our Lord and Saviour Jesus Christ.",
        "Hebrews 11:1": "Now faith is the substance of things hoped for, the evidence of things not seen.",
        "2 Corinthians 5:7": "For we walk by faith, not by sight."
    ]
    static func text(for ref: String) -> String { sample[ref] ?? "Tap to load \(ref) (public-domain text)." }
}
