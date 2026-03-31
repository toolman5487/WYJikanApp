//
//  AnimeDetailDateFormatting.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

enum AnimeDetailDateFormatting {

    // MARK: - Aired Period

    static func localizedPeriod(from aired: AnimeAiredDTO?) -> String? {
        guard let aired else { return nil }
        if let fromProp = aired.prop?.from,
           let y = fromProp.year, let m = fromProp.month, let d = fromProp.day {
            let start = chineseDateString(year: y, month: m, day: d)
            if let toProp = aired.prop?.to,
               let y2 = toProp.year, let m2 = toProp.month, let d2 = toProp.day {
                let end = chineseDateString(year: y2, month: m2, day: d2)
                return "\(start) 至 \(end)"
            }
            return start
        }
        if let fromDate = dateFromISOString(aired.from) {
            let start = chineseDateStringFromUTC(fromDate)
            if let toDate = dateFromISOString(aired.to) {
                let end = chineseDateStringFromUTC(toDate)
                return "\(start) 至 \(end)"
            }
            return start
        }
        if let raw = aired.string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            if let parsed = parseEnglishMalAiredString(raw) {
                return parsed
            }
            return raw
        }
        return nil
    }

    // MARK: - Broadcast Schedule

    static func sourceTimeZoneIdentifier(for broadcast: AnimeBroadcastDTO) -> String {
        if let id = broadcast.timezone?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty,
           TimeZone(identifier: id) != nil {
            return id
        }
        let hint = (broadcast.string ?? "") + (broadcast.time ?? "")
        if hint.localizedCaseInsensitiveContains("jst") {
            return "Asia/Tokyo"
        }
        return "Asia/Tokyo"
    }

    static func localBroadcastString(
        dayEnglish: String,
        timeHHMM: String,
        sourceTimeZoneIdentifier: String
    ) -> String? {
        guard let weekday = calendarWeekdayComponent(fromEnglishDay: dayEnglish),
              let (hour, minute) = parseHourMinute(timeHHMM),
              let sourceTZ = TimeZone(identifier: sourceTimeZoneIdentifier) else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = sourceTZ

        var match = DateComponents()
        match.weekday = weekday
        match.hour = hour
        match.minute = minute

        let anchor = Date()
        guard let occurrence = calendar.nextDate(
            after: anchor,
            matching: match,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else { return nil }

        return localizedWeekdayAndTime(from: occurrence)
    }

    static func localBroadcastFromEnglishString(_ raw: String) -> String? {
        let pattern =
            #"(?i)(Monday|Mondays|Tuesday|Tuesdays|Wednesday|Wednesdays|Thursday|Thursdays|Friday|Fridays|Saturday|Saturdays|Sunday|Sundays)\s+at\s+(\d{1,2}:\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              match.numberOfRanges >= 3,
              let dayRange = Range(match.range(at: 1), in: raw),
              let timeRange = Range(match.range(at: 2), in: raw) else { return nil }

        let dayStr = String(raw[dayRange])
        let timeStr = String(raw[timeRange])
        let tzId = sourceTimeZoneIdentifier(
            for: AnimeBroadcastDTO(day: dayStr, time: timeStr, timezone: nil, string: raw)
        )
        return localBroadcastString(dayEnglish: dayStr, timeHHMM: timeStr, sourceTimeZoneIdentifier: tzId)
    }

    static func weekdayChinese(from english: String) -> String {
        let lower = english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("mon") { return "每週一" }
        if lower.hasPrefix("tue") { return "每週二" }
        if lower.hasPrefix("wed") { return "每週三" }
        if lower.hasPrefix("thu") { return "每週四" }
        if lower.hasPrefix("fri") { return "每週五" }
        if lower.hasPrefix("sat") { return "每週六" }
        if lower.hasPrefix("sun") { return "每週日" }
        return english
    }

    static func translateBroadcastEnglishString(_ raw: String) -> String {
        var result = raw
        let pairs: [(String, String)] = [
            ("Mondays", "每週一"), ("Monday", "每週一"),
            ("Tuesdays", "每週二"), ("Tuesday", "每週二"),
            ("Wednesdays", "每週三"), ("Wednesday", "每週三"),
            ("Thursdays", "每週四"), ("Thursday", "每週四"),
            ("Fridays", "每週五"), ("Friday", "每週五"),
            ("Saturdays", "每週六"), ("Saturday", "每週六"),
            ("Sundays", "每週日"), ("Sunday", "每週日")
        ]
        for (en, zh) in pairs {
            result = result.replacingOccurrences(of: en, with: zh, options: .caseInsensitive)
        }
        result = result.replacingOccurrences(of: " at ", with: " ", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "(JST)", with: "", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "Unknown", with: "未定", options: .caseInsensitive)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Methods

    private static func chineseDateString(year: Int, month: Int, day: Int) -> String {
        "\(year) 年 \(month) 月 \(day) 日"
    }

    private static func chineseDateStringFromUTC(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return chineseDateString(year: y, month: m, day: d)
    }

    private static func dateFromISOString(_ raw: String?) -> Date? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) {
            return d
        }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) {
            return d
        }
        iso.formatOptions = [.withFullDate]
        return iso.date(from: raw)
    }

    private static func parseEnglishMalAiredString(_ raw: String) -> String? {
        let segments = raw.components(separatedBy: " to ")
        guard let first = segments.first else { return nil }
        let head = first.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !head.isEmpty else { return nil }

        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        inputFormatter.dateFormat = "MMM d, yyyy"

        guard let startDate = inputFormatter.date(from: head) else { return nil }
        let start = chineseDateStringFromUTC(startDate)

        guard segments.count >= 2 else { return start }
        let tail = segments.dropFirst().joined(separator: " to ").trimmingCharacters(in: .whitespacesAndNewlines)
        let tailLower = tail.lowercased()
        if tailLower == "?" || tailLower.hasPrefix("?") {
            return start
        }
        if let endDate = inputFormatter.date(from: tail) {
            let end = chineseDateStringFromUTC(endDate)
            return "\(start) 至 \(end)"
        }
        return start
    }

    private static func calendarWeekdayComponent(fromEnglishDay day: String) -> Int? {
        let lower = day.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("sun") { return 1 }
        if lower.hasPrefix("mon") { return 2 }
        if lower.hasPrefix("tue") { return 3 }
        if lower.hasPrefix("wed") { return 4 }
        if lower.hasPrefix("thu") { return 5 }
        if lower.hasPrefix("fri") { return 6 }
        if lower.hasPrefix("sat") { return 7 }
        return nil
    }

    private static func parseHourMinute(_ raw: String) -> (Int, Int)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":")
        guard let first = parts.first, let h = Int(first) else { return nil }
        guard parts.count >= 2 else { return nil }
        let minutePart = parts[1].prefix(2)
        guard let m = Int(minutePart) else { return nil }
        return (h, m)
    }

    private static func localizedWeekdayAndTime(from date: Date) -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let weekday = calendar.component(.weekday, from: date)
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        let idx = weekday - 1
        let weekdayPart: String
        if idx >= 0, idx < labels.count {
            weekdayPart = "週" + labels[idx]
        } else {
            weekdayPart = ""
        }

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "HH:mm"

        let timePart = timeFormatter.string(from: date)
        if weekdayPart.isEmpty {
            return timePart
        }
        return "\(weekdayPart) \(timePart)"
    }
}
