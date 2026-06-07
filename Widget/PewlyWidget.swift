import WidgetKit
import SwiftUI

private let canvas = Color(red: 0.961, green: 0.953, blue: 0.937)
private let ink = Color(red: 0.141, green: 0.133, blue: 0.122)
private let mid = Color(red: 0.435, green: 0.416, blue: 0.388)
private let accent = Color(red: 0.227, green: 0.290, blue: 0.471)
private let gold = Color(red: 0.725, green: 0.580, blue: 0.286)

struct PewlyEntry: TimelineEntry { let date: Date; let data: WidgetData }

struct PewlyProvider: TimelineProvider {
    func placeholder(in context: Context) -> PewlyEntry { PewlyEntry(date: Date(), data: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (PewlyEntry) -> Void) { completion(PewlyEntry(date: Date(), data: WidgetBridge.read())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PewlyEntry>) -> Void) {
        completion(Timeline(entries: [PewlyEntry(date: Date(), data: WidgetBridge.read())], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct PewlyWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: PewlyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("PEWLY").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(accent); Spacer(); Image(systemName: "checkmark.seal.fill").font(.system(size: 11)).foregroundStyle(accent) }
            if !entry.data.verseRef.isEmpty {
                Text(entry.data.verseRef).font(.system(size: 12, weight: .semibold, design: .serif)).foregroundStyle(gold)
                Text(entry.data.verseText).font(.system(size: family == .systemSmall ? 12 : 14, design: .serif)).foregroundStyle(ink).lineLimit(family == .systemSmall ? 3 : 4)
            } else {
                Text(entry.data.verseText).font(.system(size: 13)).foregroundStyle(mid)
            }
            if family != .systemSmall, !entry.data.actions.isEmpty {
                Spacer(minLength: 2)
                ForEach(entry.data.actions.prefix(2), id: \.self) { a in
                    HStack(spacing: 5) { Image(systemName: "circle").font(.system(size: 9)).foregroundStyle(accent); Text(a).font(.system(size: 11)).foregroundStyle(mid).lineLimit(1) }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(canvas, for: .widget)
    }
}

@main
struct PewlyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PewlyWidget", provider: PewlyProvider()) { PewlyWidgetView(entry: $0) }
            .configurationDisplayName("This week")
            .description("Your latest scripture and what to live out.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
