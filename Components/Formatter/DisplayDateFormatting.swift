//
//  DisplayDateFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum DisplayDateFormatting {

    private static let iso8601WithFractionalSeconds = Date.ISO8601FormatStyle(
        includingFractionalSeconds: true
    )

    private static let iso8601WithoutFractionalSeconds = Date.ISO8601FormatStyle(
        includingFractionalSeconds: false
    )

    private static let fullDateStrategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    private static let englishMalDateStrategy = Date.ParseStrategy(
        format: "\(month: .abbreviated) \(day: .defaultDigits), \(year: .defaultDigits)",
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: .gmt
    )

    static func date(fromISO8601 rawValue: String?) -> Date? {
        guard let rawValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        return [iso8601WithFractionalSeconds, iso8601WithoutFractionalSeconds]
            .lazy
            .compactMap { try? Date(rawValue, strategy: $0) }
            .first
            ?? (try? Date(rawValue, strategy: fullDateStrategy))
    }

    static func date(fromEnglishMalDate rawValue: String) -> Date? {
        try? Date(rawValue, strategy: englishMalDateStrategy)
    }

    static func displayDateString(
        fromISO8601 rawValue: String?,
        fallbackToRaw: Bool = true
    ) -> String? {
        guard let rawValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        guard let date = date(fromISO8601: rawValue) else {
            return fallbackToRaw ? rawValue : nil
        }

        return mediumDateString(from: date)
    }

    static func mediumDateString(from date: Date) -> String {
        date.formatted(
            .dateTime
                .year()
                .month(.abbreviated)
                .day()
                .locale(.autoupdatingCurrent)
        )
    }

    static func localHourMinuteString(from date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(.autoupdatingCurrent)
        )
    }
}
