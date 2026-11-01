import Foundation

@main
struct PromotionVerification {
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(100_000)
        // 募集中／終了後の既存取得者／終了時刻以降の新規取得者。
        precondition(PromotionPolicy.qualifies(originalPurchaseDate: end,
                                              enrollmentOpen: true, enrollmentEndsAt: nil))
        precondition(PromotionPolicy.qualifies(originalPurchaseDate: start,
                                              enrollmentOpen: false, enrollmentEndsAt: end))
        precondition(!PromotionPolicy.qualifies(originalPurchaseDate: end,
                                               enrollmentOpen: false, enrollmentEndsAt: end))
        precondition(!PromotionPolicy.qualifies(originalPurchaseDate: end.addingTimeInterval(1),
                                               enrollmentOpen: false, enrollmentEndsAt: end))
        precondition(!PromotionPolicy.qualifies(originalPurchaseDate: start,
                                               enrollmentOpen: false, enrollmentEndsAt: nil))
        let day: TimeInterval = 86_400
        precondition(!FeedbackSchedule.isDue(firstUse: start, lastRequest: nil,
                                            hasStudied: true, now: start.addingTimeInterval(4 * day - 1)))
        precondition(FeedbackSchedule.isDue(firstUse: start, lastRequest: nil,
                                           hasStudied: true, now: start.addingTimeInterval(4 * day)))
        precondition(!FeedbackSchedule.isDue(firstUse: start, lastRequest: nil,
                                            hasStudied: false, now: start.addingTimeInterval(5 * day)))
        let asked = start.addingTimeInterval(4 * day)
        precondition(!FeedbackSchedule.isDue(firstUse: start, lastRequest: asked,
                                            hasStudied: true, now: asked.addingTimeInterval(4 * day - 1)))
        precondition(FeedbackSchedule.isDue(firstUse: start, lastRequest: asked,
                                           hasStudied: true, now: asked.addingTimeInterval(4 * day)))
        precondition(!FeedbackSchedule.isDue(firstUse: start, lastRequest: asked,
                                            hasStudied: true, now: start))
        precondition(SupportConfig.email == "contact@safa-lang.com")
        print("PASS: lifetime eligibility, promotion closing boundary, four-day feedback interval")
    }
}
