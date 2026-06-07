import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var note: SermonNote
    @State private var editing = false
    @State private var openVerse: VerseRef?
    @State private var confirmDelete = false
    @State private var showShare = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerBlock
                versesBlock
                pointsBlock
                reflectionBlock
                prayerBlock
                actionsBlock
            }.padding(16).padding(.bottom, 20)
        }
        .screenBackground()
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.canvas, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.isPro ? (showShare = true) : (showPaywall = true) } label: { Image(systemName: "square.and.arrow.up") }
            }
            ToolbarItem(placement: .topBarTrailing) { Button { editing = true } label: { Image(systemName: "pencil") } }
            ToolbarItem(placement: .topBarTrailing) { Button(role: .destructive) { confirmDelete = true } label: { Image(systemName: "trash") }.tint(Theme.textMid) }
        }
        .sheet(isPresented: $showShare) { ShareCardView(note: note).presentationDetents([.large]) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $openVerse) { v in VerseSheet(ref: v.ref) }
        .sheet(isPresented: $editing) {
            NoteEditorView(note: note, isNew: false, onSave: { note = $0; store.update($0); editing = false }, onClose: { editing = false })
        }
        .confirmationDialog("Delete this note?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.delete(note); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title).font(Theme.serif(24, .bold)).foregroundStyle(Theme.textHi)
            Text("\(note.speaker) • \(note.date.formatted(.dateTime.weekday(.wide).month().day())) • \(note.durationMin)min")
                .font(.subheadline).foregroundStyle(Theme.textMid)
            HStack(spacing: 6) {
                KindTag(kind: note.kind)
                if note.aiGenerated { Label("AI draft", systemImage: "sparkles").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.gold) }
            }
        }
    }

    @ViewBuilder private var versesBlock: some View {
        if !note.verses.isEmpty {
            section("Scriptures", icon: "book.fill") {
                ForEach(note.verses) { v in
                    Button { openVerse = v } label: {
                        HStack {
                            Text(v.ref).font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(Theme.accent)
                            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textLow)
                        }.padding(.vertical, 2)
                    }
                    if v.id != note.verses.last?.id { Divider().overlay(Theme.hairline) }
                }
            }
        }
    }

    @ViewBuilder private var pointsBlock: some View {
        if !note.points.isEmpty {
            section("Key points", icon: "list.bullet") {
                ForEach(note.points, id: \.self) { p in
                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 7)
                        Text(p).font(.system(size: 15)).foregroundStyle(Theme.textHi).lineSpacing(3)
                    }
                }
            }
        }
    }

    @ViewBuilder private var reflectionBlock: some View {
        if !note.reflection.isEmpty {
            section("Reflection", icon: "quote.opening") {
                Text(note.reflection).font(.system(size: 15)).foregroundStyle(Theme.textHi).lineSpacing(3).italic()
            }
        }
    }

    @ViewBuilder private var prayerBlock: some View {
        if !note.prayerItems.isEmpty {
            section("Prayer", icon: "hands.and.sparkles.fill") {
                ForEach(note.prayerItems, id: \.self) { Text("• \($0)").font(.system(size: 15)).foregroundStyle(Theme.textHi) }
            }
        }
    }

    @ViewBuilder private var actionsBlock: some View {
        if !note.actions.isEmpty {
            section("Action items", icon: "checkmark.seal.fill") {
                ForEach(note.actions) { a in
                    Button { toggle(a) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: a.done ? "checkmark.circle.fill" : "circle").foregroundStyle(a.done ? Theme.success : Theme.accent)
                            Text(a.text).font(.system(size: 15)).foregroundStyle(a.done ? Theme.textLow : Theme.textHi).strikethrough(a.done)
                            Spacer()
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func toggle(_ a: ActionItem) {
        if let i = note.actions.firstIndex(where: { $0.id == a.id }) { note.actions[i].done.toggle(); store.update(note) }
    }
    @ViewBuilder private func section<C: View>(_ title: String, icon: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) { Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.accent); SectionHeader(title: title) }
            content()
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)
    }
}

struct VerseSheet: View {
    let ref: String
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var loading = true
    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Theme.hairline).frame(width: 36, height: 5).padding(.top, 8)
            Text(ref).font(Theme.serif(22, .bold)).foregroundStyle(Theme.accent)
            if loading { ProgressView().padding(.vertical, 20) }
            else {
                Text(text).font(.system(size: 18, design: .serif)).foregroundStyle(Theme.textHi).lineSpacing(6).multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            Text("World English Bible · public domain").font(.caption2).foregroundStyle(Theme.textLow)
            Spacer()
        }
        .frame(maxWidth: .infinity).screenBackground().presentationDetents([.height(300), .medium])
        .task {
            text = VerseText.text(for: ref)   // instant fallback
            if let live = try? await PewlyAPI.verse(ref) { text = live }
            loading = false
        }
    }
}
