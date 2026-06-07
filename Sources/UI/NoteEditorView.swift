import SwiftUI

/// Fully editable structured note. Directly answers the head's #1 complaint: "you cannot edit the notes".
struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var note: SermonNote
    var isNew: Bool
    var onSave: (SermonNote) -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isNew {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                            Text("Pewly drafted this from the sermon — edit anything below.")
                                .font(.system(size: 13)).foregroundStyle(Theme.textMid)
                        }.frame(maxWidth: .infinity, alignment: .leading).card(Theme.gold.opacity(0.08), padding: 12)
                    }

                    // Title / speaker / kind
                    VStack(spacing: 12) {
                        field("Title", text: $note.title, serif: true)
                        field("Speaker", text: $note.speaker)
                        Picker("Type", selection: $note.kind) {
                            ForEach(NoteKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.menu).tint(Theme.accent).frame(maxWidth: .infinity, alignment: .leading)
                    }.card(padding: 16)

                    editList("Scriptures", icon: "book", items: $note.verses,
                             text: { $0.ref }, set: { $0.ref = $1 }, make: { VerseRef(ref: "") })
                    editStrings("Key points", icon: "list.bullet", items: $note.points)

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Reflection")
                        TextEditor(text: $note.reflection).frame(minHeight: 70).scrollContentBackground(.hidden)
                            .padding(8).background(Theme.elevated, in: RoundedRectangle(cornerRadius: 10)).font(.system(size: 15))
                    }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)

                    editStrings("Prayer", icon: "hands.and.sparkles", items: $note.prayerItems)
                    editActions(items: $note.actions)
                }.padding(16).padding(.bottom, 90)
            }
            .screenBackground()
            .navigationTitle(isNew ? "Review & edit" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(isNew ? "Discard" : "Cancel") { onClose() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button(isNew ? "Save to my notes" : "Save changes") { onSave(note) }
                    .buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 16).padding(.vertical, 10).background(Theme.canvas)
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, serif: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textLow)
            TextField(label, text: text).font(serif ? Theme.serif(18) : .system(size: 16)).foregroundStyle(Theme.textHi)
        }
    }

    @ViewBuilder private func editStrings(_ title: String, icon: String, items: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            ForEach(Array(items.wrappedValue.indices), id: \.self) { i in
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.accent)
                    TextField("…", text: Binding(get: { items.wrappedValue[i] }, set: { items.wrappedValue[i] = $0 }), axis: .vertical)
                        .font(.system(size: 15)).foregroundStyle(Theme.textHi)
                    Button { items.wrappedValue.remove(at: i) } label: { Image(systemName: "minus.circle").foregroundStyle(Theme.textLow) }
                }
            }
            Button { items.wrappedValue.append("") } label: { Label("Add", systemImage: "plus").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent) }
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)
    }

    @ViewBuilder private func editList<T: Identifiable>(_ title: String, icon: String, items: Binding<[T]>,
        text: @escaping (T) -> String, set: @escaping (inout T, String) -> Void, make: @escaping () -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            ForEach(Array(items.wrappedValue.indices), id: \.self) { i in
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.gold)
                    TextField("e.g. John 3:16", text: Binding(
                        get: { text(items.wrappedValue[i]) },
                        set: { var v = items.wrappedValue[i]; set(&v, $0); items.wrappedValue[i] = v })).font(.system(size: 15)).foregroundStyle(Theme.textHi)
                    Button { items.wrappedValue.remove(at: i) } label: { Image(systemName: "minus.circle").foregroundStyle(Theme.textLow) }
                }
            }
            Button { items.wrappedValue.append(make()) } label: { Label("Add", systemImage: "plus").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent) }
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)
    }

    @ViewBuilder private func editActions(items: Binding<[ActionItem]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Action items")
            ForEach(Array(items.wrappedValue.indices), id: \.self) { i in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle").font(.system(size: 12)).foregroundStyle(Theme.accent)
                    TextField("Something to do this week", text: Binding(get: { items.wrappedValue[i].text }, set: { items.wrappedValue[i].text = $0 }), axis: .vertical)
                        .font(.system(size: 15)).foregroundStyle(Theme.textHi)
                    Button { items.wrappedValue.remove(at: i) } label: { Image(systemName: "minus.circle").foregroundStyle(Theme.textLow) }
                }
            }
            Button { items.wrappedValue.append(ActionItem(text: "")) } label: { Label("Add", systemImage: "plus").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent) }
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 16)
    }
}
