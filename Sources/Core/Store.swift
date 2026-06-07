import SwiftUI

/// App state + persistence. `transcribeAndStructure` is the plug point where the real engine
/// (端侧 Speech 转写 → linkapi 结构化 → bible-api 经文文本) will slot in.
@MainActor
final class Store: ObservableObject {
    @Published var notes: [SermonNote] = []
    @Published var prayers: [PrayerEntry] = []
    @Published var isPro = false

    private let key = "pewly.state.v1"
    private let kvs = NSUbiquitousKeyValueStore.default
    init() {
        load()
        // iCloud sync (4.2.2 "transfer between devices"): merge newest, observe external changes.
        NotificationCenter.default.addObserver(self, selector: #selector(iCloudChanged), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kvs)
        kvs.synchronize(); mergeFromiCloud()
    }

    @objc private func iCloudChanged() { Task { @MainActor in mergeFromiCloud() } }
    private func mergeFromiCloud() {
        guard let d = kvs.data(forKey: key), let snap = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        // last-write-wins per record by dateAdded/date; simple union keeping the larger set
        if snap.notes.count >= notes.count { notes = snap.notes }
        if snap.prayers.count >= prayers.count { prayers = snap.prayers }
        if snap.isPro { isPro = true }
    }

    var openActions: [(SermonNote, ActionItem)] {
        notes.flatMap { n in n.actions.filter { !$0.done }.map { (n, $0) } }
    }

    func add(_ n: SermonNote) {
        notes.insert(n, at: 0); save()
        if !n.actions.isEmpty { Task { if await NotificationService.requestAuth() { NotificationService.scheduleWeeklyReview() } } }
    }
    func update(_ n: SermonNote) { if let i = notes.firstIndex(where: { $0.id == n.id }) { notes[i] = n; save() } }
    func delete(_ n: SermonNote) { notes.removeAll { $0.id == n.id }; save() }

    func addPrayer(_ p: PrayerEntry) { prayers.insert(p, at: 0); save() }
    func updatePrayer(_ p: PrayerEntry) { if let i = prayers.firstIndex(where: { $0.id == p.id }) { prayers[i] = p; save() } }
    func deletePrayer(_ p: PrayerEntry) { prayers.removeAll { $0.id == p.id }; save() }

    func toggleAction(_ note: SermonNote, _ action: ActionItem) {
        guard var n = notes.first(where: { $0.id == note.id }),
              let ai = n.actions.firstIndex(where: { $0.id == action.id }) else { return }
        n.actions[ai].done.toggle(); update(n)
    }

    /// Plug point: capture sermon audio → transcribe (on-device Speech) → structure (linkapi)
    /// → resolve verses (public-domain bible-api). Today returns a curated sample so the flow runs.
    func transcribeAndStructure() -> SermonNote { Self.freshSample() }

    // MARK: persistence
    private func save() {
        if let d = try? JSONEncoder().encode(Snapshot(notes: notes, prayers: prayers, isPro: isPro)) {
            UserDefaults.standard.set(d, forKey: key)
            kvs.set(d, forKey: key); kvs.synchronize()   // push to iCloud
        }
        WidgetPublisher.publish(notes: notes)             // share to widget
    }
    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else {
            notes = Self.sampleNotes; prayers = Self.samplePrayers; return  // first-run demo
        }
        notes = s.notes; prayers = s.prayers; isPro = s.isPro
    }
    private struct Snapshot: Codable { var notes: [SermonNote]; var prayers: [PrayerEntry]; var isPro: Bool }
}

extension Store {
    static func d(_ daysAgo: Int) -> Date { Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())! }

    static let sampleNotes: [SermonNote] = [
        SermonNote(title: "The Fruit of the Spirit", speaker: "Pastor James", kind: .sermon, date: d(2), durationMin: 38,
            verses: [VerseRef(ref: "Galatians 5:22-23"), VerseRef(ref: "John 15:5")],
            points: ["Fruit grows from abiding, not striving",
                     "Love is the root; the rest flow from it",
                     "The Spirit produces character, not just feeling"],
            reflection: "Convicted about patience at home this week.",
            prayerItems: ["Patience with the kids", "A softer tongue"],
            actions: [ActionItem(text: "Read Galatians 5 again Wed"), ActionItem(text: "Memorize v22-23", done: true)],
            aiGenerated: true),
        SermonNote(title: "Seeking Divine Guidance", speaker: "Elder Mara", kind: .study, date: d(6), durationMin: 51,
            verses: [VerseRef(ref: "Proverbs 3:5-6"), VerseRef(ref: "James 1:5")],
            points: ["Trust precedes understanding", "Acknowledge Him in all your ways", "Ask for wisdom — He gives generously"],
            reflection: "Need to bring the job decision to prayer before acting.",
            prayerItems: ["Wisdom on the job offer"],
            actions: [ActionItem(text: "Decide by Sunday after praying")],
            aiGenerated: true),
        SermonNote(title: "Spiritual Growth", speaker: "Pastor James", kind: .prayer, date: d(13), durationMin: 22,
            verses: [VerseRef(ref: "2 Peter 3:18")],
            points: ["Grow in grace AND knowledge", "Growth is gradual and intentional"],
            reflection: "", prayerItems: ["For the small group to deepen"], actions: [], aiGenerated: false)
    ]

    static let samplePrayers: [PrayerEntry] = [
        PrayerEntry(text: "Wisdom on the job offer", date: d(5)),
        PrayerEntry(text: "Healing for Grandma", date: d(9)),
        PrayerEntry(text: "Safe travels for the mission team", date: d(20), answered: true, answeredNote: "They arrived safely 🙏")
    ]

    static func freshSample() -> SermonNote {
        SermonNote(title: "Walking by Faith", speaker: "Guest Speaker", kind: .sermon, date: Date(), durationMin: 34,
            verses: [VerseRef(ref: "Hebrews 11:1"), VerseRef(ref: "2 Corinthians 5:7")],
            points: ["Faith is substance, not wishful thinking",
                     "We walk by faith, not by sight",
                     "Obedience often precedes understanding"],
            reflection: "",
            prayerItems: ["Faith for the unknown ahead"],
            actions: [ActionItem(text: "Take the first step on the thing I've been avoiding")],
            transcript: "(full transcript of the sermon would appear here, editable)",
            aiGenerated: true)
    }
}
