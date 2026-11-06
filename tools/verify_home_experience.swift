import Foundation

@main
struct HomeExperienceVerification {
    static func main() throws {
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        let data = try Data(contentsOf: resources.appendingPathComponent("home_heroes.json"))
        let catalog = HomeHeroCatalog.decode(data)!
        precondition(!catalog.heroes.isEmpty)
        precondition(catalog.resolvedID(UUID().uuidString) == catalog.defaultID)
        precondition(catalog.hero(for: "none") == nil)
        precondition(catalog.resolvedID("none") == "none")
        let savedID = catalog.heroes[0].id
        precondition(catalog.hero(for: savedID)?.id == savedID)
        // Reorder and image replacement preserve the saved user ID.
        let reversed = HomeHeroCatalog(schema: 1, defaultID: catalog.defaultID, heroes: Array(catalog.heroes.reversed()))
        precondition(reversed.resolvedID(savedID) == savedID)
        let replaced = HomeHeroCatalog(schema: 1, defaultID: "anime", heroes: [
            HomeHero(id: "anime", title: "更新後", subtitle: "画像を差し替え", imageName: "home_hero_anime_v2")])
        precondition(replaced.hero(for: "anime")?.imageName == "home_hero_anime_v2")
        var raw = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        func assertRejected(_ object: [String: Any]) throws {
            let encoded = try JSONSerialization.data(withJSONObject: object)
            precondition(HomeHeroCatalog.decode(encoded) == nil)
        }
        raw["schema"] = 2
        try assertRejected(raw)
        raw["schema"] = 1
        raw["defaultID"] = UUID().uuidString
        try assertRejected(raw)
        raw["defaultID"] = catalog.defaultID
        var heroes = raw["heroes"] as! [[String: Any]]
        heroes.append(heroes[0]); raw["heroes"] = heroes
        try assertRejected(raw)
        heroes.removeLast(); heroes[0]["imageName"] = "../../outside"; raw["heroes"] = heroes
        try assertRejected(raw)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        func day(_ n: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: n, hour: 12))! }
        var log = StudyActivityLog()
        log.record(.textbook, at: day(3), calendar: calendar)
        log.record(.glossary, at: day(3), calendar: calendar)
        log.record(.textbook, at: day(3), calendar: calendar)
        log.record(.exam, at: day(8), calendar: calendar)
        let week = log.week(at: day(8), legacyAnswers: ["2026-11-04": 2], calendar: calendar)
        precondition(week.first?.id == "2026-11-02" && week.last?.id == "2026-11-08")
        precondition(week.filter(\.studied).count == 3) // Multiple sessions on one day count once.
        precondition(week[1].counts["textbook"] == 2 && week[1].counts["glossary"] == 1)
        precondition(log.week(at: day(9), calendar: calendar).filter(\.studied).isEmpty)
        let restored = try JSONDecoder().decode(StudyActivityLog.self, from: JSONEncoder().encode(log))
        precondition(restored.days == log.days)
        let place = StudyPlace(kind: .textbook, title: "節", chapterID: 1, sectionID: "1-4")
        let restoredPlace = try JSONDecoder().decode(StudyPlace.self, from: JSONEncoder().encode(place))
        precondition(restoredPlace == place)
        print("PASS: hero catalogs, stable selection, invalid input, JST weekly learning and persistence")
    }
}
