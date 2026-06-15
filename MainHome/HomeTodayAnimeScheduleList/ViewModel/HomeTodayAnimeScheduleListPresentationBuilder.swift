//
//  HomeTodayAnimeScheduleListPresentationBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

nonisolated struct HomeTodayAnimeScheduleListPresentationBuilder: Sendable {
    private let textFormatter = MainHomeMediaTextFormatter()

    func timelineItem(from dto: HomeTodayAnimeDTO) -> HomeTodayAnimeTimelineItem? {
        let timeInfo = timeInfo(from: dto.broadcast)

        return HomeTodayAnimeTimelineItem(
            id: dto.id,
            title: textFormatter.preferredTitle(
                japanese: dto.titleJapanese,
                english: dto.titleEnglish,
                fallback: dto.title
            ),
            typeText: textFormatter.animeTypeText(dto.type),
            scoreText: textFormatter.scoreText(dto.score, precision: 1),
            episodeText: textFormatter.episodeText(dto.episodes),
            statusText: textFormatter.animeStatusText(dto.status),
            studioText: textFormatter.studioText(dto.studios),
            synopsisPreview: textFormatter.synopsisPreview(dto.synopsis, limit: 96),
            imageURL: posterURL(from: dto),
            timeSectionTitle: timeInfo.sectionTitle,
            timeSortValue: timeInfo.sortValue,
            broadcastText: timeInfo.displayText
        )
    }

    func groupedSections(from items: [HomeTodayAnimeTimelineItem]) -> [HomeTodayAnimeTimeSection] {
        let sortedItems = items.sorted {
            if $0.timeSortValue == $1.timeSortValue {
                return $0.title < $1.title
            }
            return $0.timeSortValue < $1.timeSortValue
        }

        let grouped = Dictionary(grouping: sortedItems, by: \.timeSectionTitle)
        let orderedTitles = sortedItems.map(\.timeSectionTitle).reduce(into: [String]()) { result, title in
            if !result.contains(title) {
                result.append(title)
            }
        }

        return orderedTitles.compactMap { title in
            guard let items = grouped[title] else { return nil }
            return HomeTodayAnimeTimeSection(title: title, items: items)
        }
    }
}

private extension HomeTodayAnimeScheduleListPresentationBuilder {
    nonisolated func timeInfo(from broadcast: AnimeBroadcastDTO?) -> (
        sectionTitle: String,
        sortValue: Int,
        displayText: String
    ) {
        if let presentation = AnimeDetailDateFormatting.localBroadcastPresentation(from: broadcast) {
            return (
                presentation.sectionTitle,
                presentation.sortValue,
                presentation.displayText
            )
        }

        return ("播出時間未定", Int.max, broadcastDisplayText(from: broadcast) ?? "播出時間未定")
    }

    nonisolated func broadcastDisplayText(from broadcast: AnimeBroadcastDTO?) -> String? {
        guard let broadcast else { return nil }

        if let raw = textFormatter.normalizedText(broadcast.string) {
            return AnimeDetailDateFormatting.localBroadcastFromEnglishString(raw)
                ?? AnimeDetailDateFormatting.translateBroadcastEnglishString(raw)
        }

        let day = textFormatter.normalizedText(broadcast.day) ?? ""
        let time = textFormatter.normalizedText(broadcast.time) ?? ""
        guard !day.isEmpty, !time.isEmpty else { return nil }

        return AnimeDetailDateFormatting.localBroadcastString(
            dayEnglish: day,
            timeHHMM: time,
            sourceTimeZoneIdentifier: AnimeDetailDateFormatting.sourceTimeZoneIdentifier(for: broadcast)
        ) ?? "\(AnimeDetailDateFormatting.weekdayChinese(from: day)) \(time)"
    }

    nonisolated func posterURL(from dto: HomeTodayAnimeDTO) -> URL? {
        JikanImageURLResolver.url(from: dto.images, tier: .poster)
    }
}
