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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        func date(_ day: Int, hour: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
        }
        let firstUse = date(1, hour: 23)
        // 初回利用日を1日目と数える。24時間×3の経過ではない。
        precondition(!FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: nil,
                                            hasStudied: true, now: date(2, hour: 23), calendar: calendar))
        precondition(FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: nil,
                                           hasStudied: true, now: date(3), calendar: calendar))
        precondition(!FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: nil,
                                            hasStudied: false, now: date(3), calendar: calendar))
        let asked = date(3, hour: 20)
        precondition(!FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: asked,
                                            hasStudied: true, now: date(9, hour: 23), calendar: calendar))
        precondition(FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: asked,
                                           hasStudied: true, now: date(10), calendar: calendar))
        // 長く未使用でも依頼はまとめず、その時の学習後に1回だけ。
        precondition(FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: asked,
                                           hasStudied: true, now: date(20), calendar: calendar))
        precondition(!FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: asked,
                                            hasStudied: true, now: firstUse, calendar: calendar))
        precondition(!FeedbackSchedule.isDue(firstUse: firstUse, lastRequest: nil,
                                            hasStudied: true, now: date(1), calendar: calendar))
        // タブを開いただけ・バックグラウンド滞在だけでは学習完了にしない。
        var shortStudy = StudyExposure()
        shortStudy.resume(at: start)
        precondition(!shortStudy.finish(at: start.addingTimeInterval(29)))
        var sufficientStudy = StudyExposure()
        sufficientStudy.resume(at: start)
        sufficientStudy.resume(at: start.addingTimeInterval(10)) // 重複通知で開始時刻をリセットしない。
        precondition(sufficientStudy.finish(at: start.addingTimeInterval(30)))
        precondition(!sufficientStudy.finish(at: start.addingTimeInterval(120))) // 同じ離脱を二重計上しない。
        var interruptedStudy = StudyExposure()
        interruptedStudy.resume(at: start)
        interruptedStudy.pause(at: start.addingTimeInterval(20))
        interruptedStudy.pause(at: start.addingTimeInterval(200))
        interruptedStudy.resume(at: start.addingTimeInterval(600))
        precondition(interruptedStudy.finish(at: start.addingTimeInterval(610))) // 表示20秒+10秒。
        var backgroundOnly = StudyExposure()
        backgroundOnly.resume(at: start)
        backgroundOnly.pause(at: start.addingTimeInterval(10))
        precondition(!backgroundOnly.finish(at: start.addingTimeInterval(1000)))
        var backwardsClock = StudyExposure()
        backwardsClock.resume(at: start)
        precondition(!backwardsClock.finish(at: start.addingTimeInterval(-1)))
        precondition(SupportConfig.email == "contact@safa-lang.com")
        print("PASS: lifetime eligibility, third-day/weekly feedback, meaningful study boundary")
    }
}
