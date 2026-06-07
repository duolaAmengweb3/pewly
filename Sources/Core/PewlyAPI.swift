import Foundation

enum APIError: LocalizedError {
    case empty, offline, server(String)
    var errorDescription: String? {
        switch self {
        case .empty: return "Nothing was recorded. Try again closer to the speaker."
        case .offline: return "No connection. Pewly needs the internet to organize the notes."
        case .server(let m): return m
        }
    }
}

/// Talks to the Pewly Worker: sermon transcript → structured note, and public-domain verse text.
enum PewlyAPI {
    static let base = URL(string: "https://pewly-api.hxu92521.workers.dev")!

    static func structure(transcript: String, durationMin: Int) async throws -> SermonNote {
        let t = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { throw APIError.empty }
        var req = URLRequest(url: base.appendingPathComponent("v1/structure"))
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "Content-Type"); req.timeoutInterval = 90
        req.httpBody = try JSONSerialization.data(withJSONObject: ["transcript": t, "durationMin": durationMin])
        let data: Data, resp: URLResponse
        do { (data, resp) = try await URLSession.shared.data(for: req) } catch { throw APIError.offline }
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            let e = try? JSONDecoder().decode(ErrDTO.self, from: data)
            throw APIError.server(e?.error ?? "Couldn't organize the notes. Try again.")
        }
        let dto = try JSONDecoder().decode(StructureDTO.self, from: data)
        return SermonNote(title: dto.title.isEmpty ? "Sermon notes" : dto.title,
                          speaker: dto.speaker, kind: .sermon, date: Date(), durationMin: durationMin,
                          verses: dto.verses.map { VerseRef(ref: $0) },
                          points: dto.points, reflection: dto.reflection,
                          prayerItems: dto.prayerItems, actions: dto.actions.map { ActionItem(text: $0) },
                          transcript: t, aiGenerated: true)
    }

    static func verse(_ ref: String) async throws -> String {
        let q = ref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ref
        let url = base.appendingPathComponent("v1/verse")
        var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "ref", value: ref)]
        _ = q
        let (data, resp) = try await URLSession.shared.data(from: comp.url!)
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let dto = try? JSONDecoder().decode(VerseDTO.self, from: data), !dto.text.isEmpty else {
            throw APIError.server("verse unavailable")
        }
        return dto.text
    }
}

private struct ErrDTO: Decodable { var error: String? }
private struct StructureDTO: Decodable {
    var title: String; var speaker: String; var verses: [String]; var points: [String]
    var reflection: String; var prayerItems: [String]; var actions: [String]
}
private struct VerseDTO: Decodable { var ref: String; var text: String }
