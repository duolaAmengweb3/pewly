import Foundation

enum NoteKind: String, Codable, CaseIterable {
    case sermon = "Sunday Sermon"
    case study = "Bible Study"
    case prayer = "Prayer Meeting"
    case personal = "Personal"
    var symbol: String {
        switch self {
        case .sermon: return "mic.fill"
        case .study: return "book.fill"
        case .prayer: return "hands.and.sparkles.fill"
        case .personal: return "person.fill"
        }
    }
}

/// A scripture reference + (public-domain) text. Verse text is filled on demand from a
/// public-domain translation (KJV/WEB) — no licensing, no key (bible-api / bundled JSON).
struct VerseRef: Identifiable, Codable, Hashable {
    var id = UUID()
    var ref: String          // "John 3:16"
    var text: String?        // filled when fetched/bundled
}

struct ActionItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done = false
}

/// The structured sermon note — every field EDITABLE (the head's #1 complaint: "you cannot edit the notes").
struct SermonNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var speaker: String
    var kind: NoteKind = .sermon
    var date: Date
    var durationMin: Int
    var verses: [VerseRef] = []
    var points: [String] = []          // 要点(可编辑)
    var reflection: String = ""        // 个人感动
    var prayerItems: [String] = []     // 祷告事项
    var actions: [ActionItem] = []     // 行动项
    var transcript: String = ""        // 全文转写
    var aiGenerated = false            // AI 整理出来的(可改)
}

/// Prayer journal entry (second scenario, rankable via `prayer journal` diff36/pop25).
struct PrayerEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var date: Date = Date()
    var answered = false
    var answeredNote: String = ""
}
