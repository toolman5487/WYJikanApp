import Foundation

nonisolated extension HomeScheduleDay {
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }

    static func fromEnglishDay(_ day: String) -> HomeScheduleDay? {
        let lower = day.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("mon") { return .monday }
        if lower.hasPrefix("tue") { return .tuesday }
        if lower.hasPrefix("wed") { return .wednesday }
        if lower.hasPrefix("thu") { return .thursday }
        if lower.hasPrefix("fri") { return .friday }
        if lower.hasPrefix("sat") { return .saturday }
        if lower.hasPrefix("sun") { return .sunday }
        return nil
    }

    static func from(
        date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HomeScheduleDay? {
        from(calendarWeekday: calendar.component(.weekday, from: date))
    }

    static func from(calendarWeekday: Int) -> HomeScheduleDay? {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}
