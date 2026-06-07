import AppIntents
import Foundation

/// "Hey Siri, record a sermon" / Shortcuts / Control Center → opens Pewly straight into recording (4.2.3).
struct RecordSermonIntent: AppIntent {
    static var title: LocalizedStringResource = "Record a sermon"
    static var description = IntentDescription("Start recording and let Pewly organize the notes.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "pewly.autoRecord")
        return .result()
    }
}

struct PewlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RecordSermonIntent(), phrases: [
            "Record a sermon with \(.applicationName)",
            "Take sermon notes in \(.applicationName)",
            "Start \(.applicationName) recording"
        ], shortTitle: "Record sermon", systemImageName: "mic.fill")
    }
}
