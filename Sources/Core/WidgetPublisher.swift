import Foundation
import WidgetKit

/// App-side: derive the widget snapshot from notes and publish to the App Group, then reload timelines.
enum WidgetPublisher {
    static func publish(notes: [SermonNote]) {
        let open = notes.flatMap { $0.actions.filter { !$0.done }.map(\.text) }
        let latestVerse = notes.first?.verses.first?.ref ?? ""
        let w = WidgetData(verseRef: latestVerse,
                           verseText: latestVerse.isEmpty ? "Your scripture of the week appears here." : VerseText.text(for: latestVerse),
                           actions: Array(open.prefix(3)),
                           noteCount: notes.count)
        if let d = try? JSONEncoder().encode(w) {
            UserDefaults(suiteName: WidgetBridge.appGroup)?.set(d, forKey: WidgetBridge.key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
