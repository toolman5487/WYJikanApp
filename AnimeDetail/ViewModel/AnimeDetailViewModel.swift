//
//  AnimeDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation

@MainActor
final class AnimeDetailViewModel: ObservableObject {

    @Published private(set) var detail: AnimeDetailDTO?
    @Published private(set) var errorMessage: String?

    private let malId: Int
    private let service: AnimeDetailServicing

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }

        errorMessage = nil

        do {
            let response = try await service.fetchAnimeDetail(malId: malId)
            detail = response.data
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }
    }

    // MARK: - Presentation (for View)

    func displayTitle(for anime: AnimeDetailDTO) -> String {
        anime.titleJapanese ?? anime.titleEnglish ?? anime.title ?? "🎬"
    }

    func posterURL(for anime: AnimeDetailDTO) -> URL? {
        let urlString =
            anime.images?.webp?.largeImageUrl ??
            anime.images?.jpg?.largeImageUrl ??
            anime.images?.webp?.imageUrl ??
            anime.images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    func airingDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let airing = anime.airing else { return "-" }
        return airing ? "連載中" : "結束連載"
    }

    func broadcastDisplayText(for anime: AnimeDetailDTO) -> String {
        if let broadcast = anime.broadcast {
            let day = broadcast.day?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let time = broadcast.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !day.isEmpty, !time.isEmpty {
                let tzId = Self.sourceTimeZoneIdentifier(for: broadcast)
                if let local = Self.localBroadcastString(
                    dayEnglish: day,
                    timeHHMM: time,
                    sourceTimeZoneIdentifier: tzId
                ) {
                    return local
                }
                return "\(Self.weekdayChinese(from: day)) \(time)"
            }
            if let string = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
                if let local = Self.localBroadcastFromEnglishString(string) {
                    return local
                }
                return Self.translateBroadcastEnglishString(string)
            }
        }
        if let airedString = anime.aired?.string?.trimmingCharacters(in: .whitespacesAndNewlines), !airedString.isEmpty {
            return airedString
        }
        return "-"
    }

    func seasonText(for anime: AnimeDetailDTO) -> String {
        let seasonLabel = Self.seasonChineseLabel(from: anime.season)
        let yearString = anime.year.map(String.init)

        switch (seasonLabel, yearString) {
        case let (s?, y?):
            return "\(y) \(s)"
        case let (s?, nil):
            return s
        case let (nil, y?):
            return y
        default:
            return "-"
        }
    }

    func joinedNames(from entities: [AnimeRelatedEntityDTO]?) -> String {
        guard let entities, !entities.isEmpty else { return "-" }
        let names = entities.compactMap(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "-" : names.joined(separator: "、")
    }

    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func scoreDisplayText(for anime: AnimeDetailDTO) -> String {
        guard let score = anime.score else { return "-" }
        return String(format: "%.2f", score) + " / 10.0"
    }

    func hasSynopsis(for anime: AnimeDetailDTO) -> Bool {
        guard let synopsis = anime.synopsis else { return false }
        return !synopsis.isEmpty
    }

    func hasStaffInfo(for anime: AnimeDetailDTO) -> Bool {
        let studioText = joinedNames(from: anime.studios)
        let producerText = joinedNames(from: anime.producers)
        let genreText = joinedNames(from: anime.genres)
        return studioText != "-" || producerText != "-" || genreText != "-"
    }

    // MARK: - Private Methods

    private static func sourceTimeZoneIdentifier(for broadcast: AnimeBroadcastDTO) -> String {
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

    private static func localBroadcastString(
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

    private static func localBroadcastFromEnglishString(_ raw: String) -> String? {
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

    private static func weekdayChinese(from english: String) -> String {
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

    private static func translateBroadcastEnglishString(_ raw: String) -> String {
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

    private static func seasonChineseLabel(from raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        switch raw.lowercased() {
        case "winter": return "冬季"
        case "spring": return "春季"
        case "summer": return "夏季"
        case "fall", "autumn": return "秋季"
        default: return raw
        }
    }
}
