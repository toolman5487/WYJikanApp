//
//  MangaReviewViewModel+Presentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

extension MangaReviewViewModel {

    // MARK: - Presentation

    func userAvatarURL(for entry: MangaReviewEntryDTO) -> URL? {
        JikanImageURLResolver.url(from: entry.user?.images, tier: .thumbnail)
    }

    func username(for entry: MangaReviewEntryDTO) -> String {
        let name = entry.user?.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "匿名用戶" : name
    }

    func scoreDisplayText(for entry: MangaReviewEntryDTO) -> String? {
        guard let score = entry.score else { return nil }
        return "\(score) / 10"
    }

    func dateDisplayText(for entry: MangaReviewEntryDTO) -> String? {
        DisplayFormatters.DateDisplay.displayDateString(
            fromISO8601: entry.date
        )
    }

    func bodyDisplayText(for entry: MangaReviewEntryDTO) -> String {
        let text = entry.review?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "（無內文）" : text
    }

    func tagLabels(for entry: MangaReviewEntryDTO) -> [String] {
        (entry.tags ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}
