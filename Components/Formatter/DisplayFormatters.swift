//
//  DisplayFormatters.swift
//  WYJikanApp
//
//

import Foundation

// MARK: - DisplayFormatters

nonisolated enum DisplayFormatters {

    // MARK: - DateParsing

    enum DateParsing {
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

        static func date(fromISO8601 raw: String?) -> Date? {
            guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else {
                return nil
            }

            return [iso8601WithFractionalSeconds, iso8601WithoutFractionalSeconds]
                .lazy
                .compactMap { try? Date(raw, strategy: $0) }
                .first
                ?? (try? Date(raw, strategy: fullDateStrategy))
        }

        static func parseEnglishMalDate(_ raw: String) -> Date? {
            try? Date(raw, strategy: englishMalDateStrategy)
        }
    }

    // MARK: - DateDisplay

    enum DateDisplay {
        static func displayDateString(
            fromISO8601 raw: String?,
            fallbackToRaw: Bool = true
        ) -> String? {
            guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else {
                return nil
            }

            guard let date = DateParsing.date(fromISO8601: raw) else {
                return fallbackToRaw ? raw : nil
            }

            return mediumDateString(from: date)
        }

        static func mediumDateString(from date: Date) -> String {
            date.formatted(mediumDateStyle)
        }

        static func localHourMinuteString(from date: Date) -> String {
            date.formatted(
                .dateTime
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
                    .locale(.autoupdatingCurrent)
            )
        }

        private static var mediumDateStyle: Date.FormatStyle {
            .dateTime
                .year()
                .month(.abbreviated)
                .day()
                .locale(.autoupdatingCurrent)
        }
    }

    // MARK: - Number

    enum Number {
        static func decimalString(for value: Int) -> String {
            value.formatted(.number.grouping(.automatic))
        }
    }
}
