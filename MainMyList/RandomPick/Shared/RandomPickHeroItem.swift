//
//  RandomPickHeroItem.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

nonisolated struct RandomPickHeroItem: Identifiable, Hashable, Sendable {
    let id: Int
    let displayTitle: String
    let posterURL: URL?
    let metadataTexts: [String]
    let synopsisPreview: String?
}

nonisolated struct RandomPickHeroStyle: Equatable, Sendable {
    let emptyBadgeText: String
    let readyBadgeText: String
    let emptySystemImageName: String
    let emptyTitle: String
    let emptyDescription: String
    let drawingText: String
}
