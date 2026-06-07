import Foundation

/// Data shared from the app to the widget via App Group. Small, derived snapshot.
struct WidgetData: Codable {
    var verseRef: String
    var verseText: String
    var actions: [String]
    var noteCount: Int
    static let empty = WidgetData(verseRef: "", verseText: "Record your first sermon in Pewly.", actions: [], noteCount: 0)
}

enum WidgetBridge {
    static let appGroup = "group.com.duolaameng.pewly"
    static let key = "pewly.widget.v1"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func read() -> WidgetData {
        guard let d = defaults?.data(forKey: key), let w = try? JSONDecoder().decode(WidgetData.self, from: d) else { return .empty }
        return w
    }
}
