//
//  AnimeDetailSectionBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

struct AnimeDetailSectionAvailability {
    let hasEpisodes: Bool
    let hasTrailer: Bool
    let hasSynopsis: Bool
    let hasCharacters: Bool
    let hasStaffOrThemes: Bool
    let hasPictures: Bool
    let hasRecommendations: Bool
}

struct AnimeDetailSectionBuilder {
    func sections(for availability: AnimeDetailSectionAvailability) -> [AnimeDetailViewModel.Section] {
        var result: [AnimeDetailViewModel.Section] = [
            .header,
            .highlights,
            .basicInfo
        ]

        if availability.hasEpisodes {
            result.append(.episodes)
        }

        result.append(.score)

        if availability.hasTrailer {
            result.append(.trailer)
        }

        if availability.hasSynopsis {
            result.append(.synopsis)
        }

        if availability.hasCharacters {
            result.append(.characters)
        }

        if availability.hasStaffOrThemes {
            result.append(.staff)
        }

        if availability.hasPictures {
            result.append(.pictures)
        }

        if availability.hasRecommendations {
            result.append(.recommendations)
        }

        return result
    }
}
