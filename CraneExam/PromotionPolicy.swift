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
    static let interval: TimeInterval = 4 * 24 * 60 * 60

    static func isDue(firstUse: Date, lastRequest: Date?, hasStudied: Bool, now: Date) -> Bool {
        hasStudied && now.timeIntervalSince(lastRequest ?? firstUse) >= interval
    }
}

enum SupportConfig {
    static let email: String? = "contact@safa-lang.com"
}
