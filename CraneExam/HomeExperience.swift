import Foundation

/// IDs are persistent user preferences. Change imageName to replace artwork, not id.
struct HomeHero: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let imageName: String
}

struct HomeHeroCatalog: Codable, Equatable {
    let schema: Int
    let defaultID: String
    let heroes: [HomeHero]
    static let preferenceKey = "cr_home_hero_id"
    static let noneID = "none"
    static let fallback = HomeHero(id: "existing", title: "いつもの景色",
                                  subtitle: "これまでのヒーロー", imageName: "home_hero_existing_v1")
    static let fallbackCatalog = HomeHeroCatalog(schema: 1, defaultID: "existing", heroes: [fallback])

    static func decode(_ data: Data) -> HomeHeroCatalog? {
        guard let catalog = try? JSONDecoder().decode(Self.self, from: data), catalog.schema == 1,
              !catalog.heroes.isEmpty, catalog.heroes.count <= 100,
              Set(catalog.heroes.map(\.id)).count == catalog.heroes.count,
              catalog.heroes.contains(where: { $0.id == catalog.defaultID }),
              catalog.heroes.allSatisfy({ hero in
                  hero.id != noneID && validName(hero.id) && validName(hero.imageName)
                  && hero.imageName.hasPrefix("home_hero_")
                  && !hero.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                  && hero.title.count <= 60 && hero.subtitle.count <= 120
              }) else { return nil }
        return catalog
    }

    private static func validName(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 100 && value.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil
    }

    func resolvedID(_ preferred: String) -> String {
        if preferred == Self.noneID { return preferred }
        return heroes.contains(where: { $0.id == preferred }) ? preferred : defaultID
    }

    func hero(for preferred: String) -> HomeHero? {
        let id = resolvedID(preferred)
        return heroes.first { $0.id == id }
    }
}

enum StudyKind: String, Codable, CaseIterable {
    case textbook, glossary, exam
    var label: String {
        switch self { case .textbook: return "教材"; case .glossary: return "用語"; case .exam: return "模試" }
    }
    var symbol: String {
        switch self { case .textbook: return "book"; case .glossary: return "character.book.closed"; case .exam: return "doc.text" }
    }
}

struct StudyPlace: Codable, Identifiable, Equatable {
    let kind: StudyKind
    let title: String
    var chapterID: Int? = nil
    var sectionID: String? = nil
    var examRound: Int? = nil
    var id: String { "\(kind.rawValue):\(sectionID ?? String(chapterID ?? examRound ?? 0))" }
}

struct StudyDay: Identifiable {
    let date: Date
    let id: String
    let counts: [String: Int]
    let hadLegacyAnswers: Bool
    var studied: Bool { hadLegacyAnswers || counts.values.contains { $0 > 0 } }
}

/// Completed foreground learning sessions, distinct from answers or understanding.
struct StudyActivityLog: Codable {
    var days: [String: [String: Int]] = [:]

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    mutating func record(_ kind: StudyKind, at date: Date, calendar: Calendar = .current) {
        let key = Self.dayKey(date, calendar: calendar)
        var counts = days[key] ?? [:]
        counts[kind.rawValue, default: 0] += 1
        days[key] = counts
    }

    func week(at now: Date = Date(), legacyAnswers: [String: Int] = [:], calendar: Calendar = .current) -> [StudyDay] {
        let today = calendar.startOfDay(for: now)
        let offset = (calendar.component(.weekday, from: today) + 5) % 7 // Monday first
        let monday = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i, to: monday) ?? today
            let key = Self.dayKey(date, calendar: calendar)
            return StudyDay(date: date, id: key, counts: days[key] ?? [:], hadLegacyAnswers: (legacyAnswers[key] ?? 0) > 0)
        }
    }
}
