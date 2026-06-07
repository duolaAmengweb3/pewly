import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0
    @State private var demoEdit = ProcessInfo.processInfo.arguments.contains("-demoEdit")
    @State private var demoRecord = ProcessInfo.processInfo.arguments.contains("-demoRecord")
    @State private var demoPaywall = ProcessInfo.processInfo.arguments.contains("-demoPaywall")

    var body: some View {
        TabView(selection: $tab) {
            NotesView().tabItem { Label("Notes", systemImage: "note.text") }.tag(0)
            PrayerJournalView().tabItem { Label("Prayer", systemImage: "hands.and.sparkles") }.tag(1)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
        }
        .sheet(isPresented: $demoEdit) {
            NoteEditorView(note: Store.sampleNotes[0], isNew: true, onSave: { _ in demoEdit = false }, onClose: { demoEdit = false })
        }
        .fullScreenCover(isPresented: $demoRecord) { RecordFlowView() }
        .sheet(isPresented: $demoPaywall) { PaywallView() }
    }
}
