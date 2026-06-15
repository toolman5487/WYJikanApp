//
//  HomeTodayAnimeBroadcastReminderFactory.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation

// MARK: - AnimeBroadcastReminderScheduling

nonisolated enum AnimeBroadcastReminderScheduling {
    static func canSubscribe(to anime: AnimeDetailDTO) -> Bool {
        isCurrentlyAiring(anime) && canSchedule(broadcast: anime.broadcast)
    }

    static func isCurrentlyAiring(_ anime: AnimeDetailDTO) -> Bool {
        if let airing = anime.airing {
            return airing
        }

        guard let status = normalized(anime.status)?.lowercased() else {
            return false
        }

        return status == "currently airing"
    }

    static func canSchedule(broadcast: AnimeBroadcastDTO?) -> Bool {
        guard let broadcast else { return false }

        let day = normalized(broadcast.day)
        let time = normalized(broadcast.time)
        if let day, let time, !day.isEmpty, !time.isEmpty {
            return HomeScheduleDay.fromEnglishDay(day) != nil && hourMinute(from: time) != nil
        }

        if let string = normalized(broadcast.string), !string.isEmpty {
            return AnimeDetailDateFormatting.localBroadcastPresentation(fromEnglishString: string) != nil
        }

        return false
    }

    static func makeReminder(
        from snapshot: AnimeBroadcastReminderSnapshot,
        now: Date = Date()
    ) -> HomeTodayAnimeBroadcastReminder? {
        makeReminder(
            animeID: snapshot.malId,
            title: snapshot.title,
            broadcast: snapshot.broadcast,
            now: now
        )
    }

    static func makeReminder(
        animeID: Int,
        title: String,
        broadcast: AnimeBroadcastDTO,
        now: Date = Date()
    ) -> HomeTodayAnimeBroadcastReminder? {
        if let dayEnglish = normalized(broadcast.day),
           let time = normalized(broadcast.time),
           let scheduleDay = HomeScheduleDay.fromEnglishDay(dayEnglish),
           let broadcastDate = nextBroadcastDate(
               day: scheduleDay,
               time: time,
               broadcast: broadcast,
               after: now
           ) {
            return reminder(
                animeID: animeID,
                title: title,
                scheduleDay: scheduleDay,
                broadcastDate: broadcastDate,
                now: now
            )
        }

        if let string = normalized(broadcast.string),
           let broadcastDate = nextBroadcastDate(fromEnglishString: string, broadcast: broadcast, after: now),
           let scheduleDay = HomeScheduleDay.from(date: broadcastDate) {
            return reminder(
                animeID: animeID,
                title: title,
                scheduleDay: scheduleDay,
                broadcastDate: broadcastDate,
                now: now
            )
        }

        return nil
    }

    // MARK: - Private Methods

    private static func reminder(
        animeID: Int,
        title: String,
        scheduleDay: HomeScheduleDay,
        broadcastDate: Date,
        now: Date
    ) -> HomeTodayAnimeBroadcastReminder? {
        var nextBroadcastDate = broadcastDate
        if nextBroadcastDate <= now {
            nextBroadcastDate = nextBroadcastDate.addingTimeInterval(7 * 24 * 60 * 60)
        }

        guard nextBroadcastDate > now else { return nil }

        return HomeTodayAnimeBroadcastReminder(
            animeID: animeID,
            title: title,
            day: scheduleDay,
            broadcastDate: nextBroadcastDate,
            scheduledDate: nextBroadcastDate
        )
    }

    private static func nextBroadcastDate(
        day: HomeScheduleDay,
        time: String,
        broadcast: AnimeBroadcastDTO,
        after now: Date
    ) -> Date? {
        guard let (hour, minute) = hourMinute(from: time),
              let sourceTimeZone = TimeZone(
                identifier: AnimeDetailDateFormatting.sourceTimeZoneIdentifier(for: broadcast)
              ) else {
            return nil
        }

        var sourceCalendar = Calendar(identifier: .gregorian)
        sourceCalendar.timeZone = sourceTimeZone

        var components = DateComponents()
        components.weekday = day.calendarWeekday
        components.hour = hour
        components.minute = minute
        components.second = 0

        return sourceCalendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

    private static func nextBroadcastDate(
        fromEnglishString raw: String,
        broadcast: AnimeBroadcastDTO,
        after now: Date
    ) -> Date? {
        let pattern =
            #"(?i)(Monday|Mondays|Tuesday|Tuesdays|Wednesday|Wednesdays|Thursday|Thursdays|Friday|Fridays|Saturday|Saturdays|Sunday|Sundays)\s+at\s+(\d{1,2}:\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              match.numberOfRanges >= 3,
              let dayRange = Range(match.range(at: 1), in: raw),
              let timeRange = Range(match.range(at: 2), in: raw) else {
            return nil
        }

        let dayEnglish = String(raw[dayRange])
        let time = String(raw[timeRange])
        guard let scheduleDay = HomeScheduleDay.fromEnglishDay(dayEnglish) else { return nil }

        let syntheticBroadcast = AnimeBroadcastDTO(
            day: dayEnglish,
            time: time,
            timezone: broadcast.timezone,
            string: raw
        )

        return nextBroadcastDate(day: scheduleDay, time: time, broadcast: syntheticBroadcast, after: now)
    }

    private static func normalized(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func hourMinute(from time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }
}

// MARK: - HomeTodayAnimeBroadcastReminderFactory

struct HomeTodayAnimeBroadcastReminderFactory {

    // MARK: - Public Methods

    func makeReminders(
        from subscriptions: [AnimeBroadcastReminderSnapshot],
        now: Date = Date()
    ) -> [HomeTodayAnimeBroadcastReminder] {
        let reminders = subscriptions.compactMap {
            AnimeBroadcastReminderScheduling.makeReminder(from: $0, now: now)
        }
        return deduplicatedReminders(reminders)
    }

    // MARK: - Private Methods

    private func deduplicatedReminders(
        _ reminders: [HomeTodayAnimeBroadcastReminder]
    ) -> [HomeTodayAnimeBroadcastReminder] {
        var seenIDs: Set<String> = []
        return reminders.filter { reminder in
            let key = "\(reminder.animeID).\(Int(reminder.scheduledDate.timeIntervalSince1970))"
            return seenIDs.insert(key).inserted
        }
    }
}
