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
        let candidates: [String?] = [
            entry.user?.images?.webp?.imageUrl,
            entry.user?.images?.jpg?.imageUrl,
            entry.user?.images?.webp?.smallImageUrl,
            entry.user?.images?.jpg?.smallImageUrl
        ]
        for candidate in candidates {
            guard let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
                  let url = URL(string: raw)
            else { continue }
            return url
        }
        return nil
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
        guard let raw = entry.date?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = iso.date(from: raw)
        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: raw)
        }
        guard let date else { return raw }
        let out = DateFormatter()
        out.locale = Locale(identifier: "zh_TW")
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: date)
    }

    func bodyDisplayText(for entry: MangaReviewEntryDTO) -> String {
        let text = entry.review?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "（無內文）" : text
    }

    func tagLabels(for entry: MangaReviewEntryDTO) -> [String] {
        (entry.tags ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}
