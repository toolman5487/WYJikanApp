//
//  DetailRecommendationPresentation.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import Foundation

enum DetailRecommendationDisplayContext: Equatable {
    case preview
    case list
}

enum DetailRecommendationSummary: Equatable {
    case reason(String)
    case votes(formatted: String)
    case fallback
}

struct DetailRecommendationRow: Identifiable, Equatable {
    let id: Int
    let malId: Int
    let title: String
    let imageURL: URL?
    let summary: DetailRecommendationSummary
    let context: DetailRecommendationDisplayContext
}

extension DetailRecommendationSummary {
    func displayText(for context: DetailRecommendationDisplayContext) -> String? {
        switch (self, context) {
        case let (.reason(content), .preview):
            return String(content.prefix(52))
        case (.reason, .list):
            return nil
        case let (.votes(formatted), .preview):
            return formatted
        case (.votes, .list):
            return nil
        case (.fallback, .preview):
            return "相似作品推薦"
        case (.fallback, .list):
            return nil
        }
    }
}
