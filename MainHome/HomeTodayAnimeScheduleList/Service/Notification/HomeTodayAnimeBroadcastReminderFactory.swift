//
//  HomeTodayAnimeBroadcastReminderFactory.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation
import OSLog

struct HomeTodayAnimeBroadcastReminderFactory {
    private struct DayReminderFetchFailure {
        let day: HomeScheduleDay
        let page: Int
        let error: any Error
    }

    private struct DayReminderFetchResult {
        let reminders: [HomeTodayAnimeBroadcastReminder]
        let failure: DayReminderFetchFailure?
    }

    private let service: HomeTodayAnimeScheduleListServicing

    init(service: HomeTodayAnimeScheduleListServicing) {
        self.service = service
    }

    func makeReminders() async throws -> [HomeTodayAnimeBroadcastReminder] {
        let now = Date()
        var reminders: [HomeTodayAnimeBroadcastReminder] = []
        var lastFailure: DayReminderFetchFailure?

        for day in HomeScheduleDay.allCases {
            let result = await fetchReminders(for: day, now: now)
            reminders.append(contentsOf: result.reminders)

            if let failure = result.failure {
                lastFailure = failure
                AppLogger.notifications.warning(
                    """
                    Today anime reminder fetch failed for day=\(failure.day.rawValue, privacy: .public) \
                    page=\(failure.page) \(failure.error.localizedDescription, privacy: .public)
                    """
                )
            }
        }

        let deduplicated = deduplicatedReminders(reminders)
        if deduplicated.isEmpty, let lastFailure {
            throw lastFailure.error
        }
        return deduplicated
    }

    private func fetchReminders(
        for day: HomeScheduleDay,
        now: Date
    ) async -> DayReminderFetchResult {
        var page = 1
        var hasNextPage = true
        var reminders: [HomeTodayAnimeBroadcastReminder] = []

        while hasNextPage, page <= HomeTodayAnimeNotificationConfig.maxPagesPerDay {
            do {
                let response = try await service.fetchSchedulePage(
                    day: day,
                    page: page,
                    limit: HomeTodayAnimeNotificationConfig.pageSize
                )
                reminders.append(
                    contentsOf: response.data.compactMap { dto in
                        makeReminder(from: dto, day: day, now: now)
                    }
                )

                hasNextPage = response.pagination?.hasNextPage == true
                page += 1
            } catch {
                return DayReminderFetchResult(
                    reminders: reminders,
                    failure: DayReminderFetchFailure(day: day, page: page, error: error)
                )
            }
        }

        return DayReminderFetchResult(reminders: reminders, failure: nil)
    }

    private func makeReminder(
        from dto: HomeTodayAnimeDTO,
        day: HomeScheduleDay,
        now: Date
    ) -> HomeTodayAnimeBroadcastReminder? {
        guard let broadcast = dto.broadcast,
              let time = Self.clean(broadcast.time),
              let broadcastDate = nextBroadcastDate(day: day, time: time, broadcast: broadcast, after: now) else {
            return nil
        }

        var nextBroadcastDate = broadcastDate
        if nextBroadcastDate <= now {
            nextBroadcastDate = nextBroadcastDate.addingTimeInterval(7 * 24 * 60 * 60)
        }

        guard nextBroadcastDate > now else { return nil }

        return HomeTodayAnimeBroadcastReminder(
            animeID: dto.id,
            title: Self.displayTitle(from: dto),
            day: day,
            broadcastDate: nextBroadcastDate,
            scheduledDate: nextBroadcastDate
        )
    }

    private func nextBroadcastDate(
        day: HomeScheduleDay,
        time: String,
        broadcast: AnimeBroadcastDTO,
        after now: Date
    ) -> Date? {
        guard let (hour, minute) = Self.hourMinute(from: time),
              let sourceTimeZone = TimeZone(identifier: AnimeDetailDateFormatting.sourceTimeZoneIdentifier(for: broadcast)) else {
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

    private func deduplicatedReminders(
        _ reminders: [HomeTodayAnimeBroadcastReminder]
    ) -> [HomeTodayAnimeBroadcastReminder] {
        var seenIDs: Set<String> = []
        return reminders.filter { reminder in
            let key = "\(reminder.animeID).\(Int(reminder.scheduledDate.timeIntervalSince1970))"
            return seenIDs.insert(key).inserted
        }
    }

    private static func displayTitle(from dto: HomeTodayAnimeDTO) -> String {
        if let japanese = clean(dto.titleJapanese) {
            return japanese
        }
        if let english = clean(dto.titleEnglish) {
            return english
        }
        if let title = clean(dto.title) {
            return title
        }
        return "未命名作品"
    }

    private static func clean(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func hourMinute(from time: String?) -> (hour: Int, minute: Int)? {
        guard let time = clean(time) else { return nil }
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return (hour, minute)
    }
}
