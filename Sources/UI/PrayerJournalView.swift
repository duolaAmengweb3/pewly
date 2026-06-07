import SwiftUI

struct PrayerJournalView: View {
    @EnvironmentObject var store: Store
    @State private var newText = ""
    @State private var adding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Button { adding = true } label: {
                        HStack { Image(systemName: "plus.circle.fill"); Text("Add a prayer request").fontWeight(.semibold); Spacer() }
                            .foregroundStyle(Theme.accent).padding(16).card(Theme.accentSoft, padding: 16)
                    }.buttonStyle(.plain)

                    if store.prayers.isEmpty { empty }
                    else {
                        let open = store.prayers.filter { !$0.answered }
                        let answered = store.prayers.filter { $0.answered }
                        if !open.isEmpty {
                            group("Praying for", open)
                        }
                        if !answered.isEmpty {
                            group("Answered 🙏", answered)
                        }
                    }
                }.padding(16)
            }
            .screenBackground()
            .navigationTitle("Prayer Journal")
            .toolbarBackground(Theme.canvas, for: .navigationBar)
        }
        .sheet(isPresented: $adding) {
            PrayerComposer { text in store.addPrayer(PrayerEntry(text: text)); adding = false } onCancel: { adding = false }
        }
    }

    @ViewBuilder private func group(_ title: String, _ items: [PrayerEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            ForEach(items) { p in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(p.text).font(.system(size: 15)).foregroundStyle(p.answered ? Theme.textMid : Theme.textHi)
                        Spacer()
                        Button { var x = p; x.answered.toggle(); store.updatePrayer(x) } label: {
                            Image(systemName: p.answered ? "checkmark.seal.fill" : "seal").foregroundStyle(p.answered ? Theme.success : Theme.textLow)
                        }
                    }
                    if !p.answeredNote.isEmpty { Text(p.answeredNote).font(.system(size: 13)).foregroundStyle(Theme.success) }
                    Text(p.date.formatted(.dateTime.month().day())).font(.system(size: 11)).foregroundStyle(Theme.textLow)
                }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 14)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            ZStack { Circle().fill(Theme.accentSoft).frame(width: 96, height: 96); Image(systemName: "hands.and.sparkles").font(.system(size: 36)).foregroundStyle(Theme.accent) }
            Text("Your prayer journal").font(Theme.serif(20, .semibold)).foregroundStyle(Theme.textHi)
            Text("Write down what you're praying for, and mark it when God answers.").font(.subheadline).foregroundStyle(Theme.textMid).multilineTextAlignment(.center).padding(.horizontal, 36)
        }
    }
}

struct PrayerComposer: View {
    @State private var text = ""
    var onSave: (String) -> Void
    var onCancel: () -> Void
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text).scrollContentBackground(.hidden).padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12)).frame(minHeight: 140).font(.system(size: 16))
                    .overlay(alignment: .topLeading) { if text.isEmpty { Text("What are you praying for?").foregroundStyle(Theme.textLow).padding(18).allowsHitTesting(false) } }
                Spacer()
            }.padding(16).screenBackground()
            .navigationTitle("New prayer").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onCancel() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { if !text.isEmpty { onSave(text) } }.fontWeight(.semibold) }
            }
        }.preferredColorScheme(.light)
    }
}
