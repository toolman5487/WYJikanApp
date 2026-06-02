//
//  MangaDetailSectionBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

struct MangaDetailSectionAvailability {
    let hasSynopsis: Bool
    let hasCharacters: Bool
    let hasPublicationInfo: Bool
    let hasThemes: Bool
    let hasPictures: Bool
    let hasRecommendations: Bool
}

struct MangaDetailSectionBuilder {
    func sections(for availability: MangaDetailSectionAvailability) -> [MangaDetailViewModel.Section] {
        var result: [MangaDetailViewModel.Section] = [
            .header,
            .highlights,
            .basicInfo,
            .score
        ]

        if availability.hasSynopsis {
            result.append(.synopsis)
        }

        if availability.hasCharacters {
            result.append(.characters)
        }

        if availability.hasPublicationInfo || availability.hasThemes || !availability.hasSynopsis {
            result.append(.publication)
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
