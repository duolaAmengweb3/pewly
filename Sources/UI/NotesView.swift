import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: Store
    @State private var showRecord = false
    @State private var showWrite = false
    @State private var showPaywall = false
    @State private var query = ""
    @State private var filter: NoteKind? = nil
    @AppStorage("pewly.autoRecord") private var autoRecord = false

    private var filtered: [SermonNote] {
        var r = store.notes
        if let f = filter { r = r.filter { $0.kind == f } }
        guard !query.isEmpty else { return r }
        let q = query.lowercased()
        return r.filter { $0.title.lowercased().contains(q) || $0.speaker.lowercased().contains(q)
            || $0.points.joined(separator: " ").lowercased().contains(q)
            || $0.verses.contains { $0.ref.lowercased().contains(q) } }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 价值露出:核心免费 + AI 买断,两个入口让区分可感知
                    Button { store.isPro ? (showRecord = true) : (showPaywall = true) } label: {
                        HStack(spacing: 12) {
                            ZStack { Circle().fill(.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "mic.fill").foregroundStyle(.white) }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Record & auto-organize").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                                    if !store.isPro { Text("PRO").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.accent).padding(.horizontal, 5).padding(.vertical, 2).background(.white, in: Capsule()) }
                                }
                                Text("AI turns the sermon into notes").font(.system(size: 12)).foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer(); Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
                        }.padding(16).background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }.buttonStyle(.plain)

                    HStack(spacing: 10) {
                        Button { showWrite = true } label: {
                            Label("Write a note", systemImage: "square.and.pencil").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                                .frame(maxWidth: .infinity).frame(height: 44).background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain)
                        Text("Free, unlimited").font(.system(size: 12)).foregroundStyle(Theme.textLow)
                        Spacer()
                    }

                    if !store.openActions.isEmpty { actionsCard }

                    if store.notes.isEmpty { empty }
                    else {
                        // 筛选 chips(4.1.4 归档/分组)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                chip("All", nil)
                                ForEach(NoteKind.allCases, id: \.self) { chip($0.rawValue, $0) }
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(filtered) { n in
                                NavigationLink { NoteDetailView(note: n) } label: { NoteCard(note: n) }.buttonStyle(.plain)
                            }
                            if filtered.isEmpty { Text("Nothing here yet.").font(.subheadline).foregroundStyle(Theme.textMid).padding(.top, 16) }
                        }
                    }
                }.padding(16)
            }
            .screenBackground().navigationTitle("Pewly").toolbarBackground(Theme.canvas, for: .navigationBar)
            .searchable(text: $query, prompt: "Search notes & verses")
        }
        .onAppear { if autoRecord { autoRecord = false; store.isPro ? (showRecord = true) : (showPaywall = true) } }
        .fullScreenCover(isPresented: $showRecord) { RecordFlowView() }
        .sheet(isPresented: $showWrite) {
            NoteEditorView(note: SermonNote(title: "", speaker: "", kind: .personal, date: Date(), durationMin: 0), isNew: true,
                           onSave: { store.add($0); showWrite = false }, onClose: { showWrite = false })
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func chip(_ label: String, _ k: NoteKind?) -> some View {
        Button { filter = k } label: {
            Text(label).font(.system(size: 13, weight: .medium))
                .foregroundStyle(filter == k ? .white : Theme.textMid)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(filter == k ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: filter == k ? 0 : 1))
        }.buttonStyle(.plain)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "To live out this week")
            ForEach(store.openActions.prefix(3), id: \.1.id) { note, act in
                Button { store.toggleAction(note, act) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "circle").foregroundStyle(Theme.accent)
                        Text(act.text).font(.system(size: 14)).foregroundStyle(Theme.textHi)
                        Spacer()
                        Text(note.title).font(.system(size: 11)).foregroundStyle(Theme.textLow).lineLimit(1)
                    }
                }.buttonStyle(.plain)
                if act.id != store.openActions.prefix(3).last?.1.id { Divider().overlay(Theme.hairline) }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 40)
            ZStack { Circle().fill(Theme.accentSoft).frame(width: 100, height: 100); Image(systemName: "note.text").font(.system(size: 38)).foregroundStyle(Theme.accent) }
            Text("No notes yet").font(Theme.serif(20, .semibold)).foregroundStyle(Theme.textHi)
            Text("Record Sunday's sermon, or write a note now — your core notes are free forever.")
                .font(.subheadline).foregroundStyle(Theme.textMid).multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }
}
