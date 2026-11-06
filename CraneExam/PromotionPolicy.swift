import Foundation

/// 無料公開の終了時は enrollmentOpen=false とし、実際の終了日時を必ず設定する。
/// 終了前に取得したApple Accountは、再インストール・機種変更後も対象。
enum PromotionPolicy {
    static let enrollmentOpen = true
    static let enrollmentEndsAt: Date? = nil

    static func qualifies(originalPurchaseDate: Date,
                          enrollmentOpen: Bool = PromotionPolicy.enrollmentOpen,
                          enrollmentEndsAt: Date? = PromotionPolicy.enrollmentEndsAt) -> Bool {
        enrollmentOpen || enrollmentEndsAt.map { originalPurchaseDate < $0 } == true
    }
}

enum FeedbackSchedule {
    static let firstRequestDay = 3
    static let repeatIntervalDays = 7
    static let minimumStudySeconds: TimeInterval = 30

    static func isDue(firstUse: Date, lastRequest: Date?, hasStudied: Bool, now: Date,
                      calendar: Calendar = .current) -> Bool {
        guard hasStudied, now >= firstUse else { return false }
        let anchor = lastRequest ?? firstUse
        guard now >= anchor else { return false }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: anchor),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        return days >= (lastRequest == nil ? firstRequestDay - 1 : repeatIntervalDays)
    }

}

/// 画面が表示され、アプリがアクティブだった時間だけを合計する。
struct StudyExposure {
    private var startedAt: Date?
    private var visibleSeconds: TimeInterval = 0

    mutating func resume(at date: Date) {
        if startedAt == nil { startedAt = date }
    }

    mutating func pause(at date: Date) {
        if let start = startedAt {
            visibleSeconds += max(0, date.timeIntervalSince(start))
            startedAt = nil
        }
    }

    mutating func finish(at date: Date) -> Bool {
        pause(at: date)
        let qualifies = visibleSeconds >= FeedbackSchedule.minimumStudySeconds
        self = StudyExposure()
        return qualifies
    }
}

enum SupportConfig {
    static let email: String? = "contact@safa-lang.com"
}
