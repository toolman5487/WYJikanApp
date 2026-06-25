//
//  SynopsisTranslationModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

nonisolated enum SynopsisTranslationState: Equatable, Sendable {
    case idle
    case translating
    case translated(String)
    case failed(String)

    var isTranslating: Bool {
        if case .translating = self {
            return true
        }
        return false
    }

    var buttonTitle: String {
        switch self {
        case .idle:
            return "翻譯劇情"
        case .failed:
            return "翻譯劇情"
        case .translating:
            return "翻譯中"
        case .translated:
            return "重新翻譯"
        }
    }

    var failureMessage: String? {
        if case let .failed(message) = self {
            return message
        }
        return nil
    }
}

nonisolated enum SynopsisTranslationContext: Sendable {
    case animeWork
    case mangaWork
    case animeEpisode
    case characterProfile
    case animeReview
    case mangaReview

    var instructions: String {
        switch self {
        case .animeWork:
            return "只輸出繁體中文譯文；保留角色名、作品名、來源標記，不加解釋，不改寫劇情。"
        case .mangaWork:
            return "只輸出繁體中文譯文；保留角色名、作品名、來源標記，不加解釋，不改寫劇情。"
        case .animeEpisode:
            return "只輸出繁體中文譯文；保留角色名、作品名、集數資訊、來源標記，不加解釋，不改寫劇情。"
        case .characterProfile:
            return "只輸出繁體中文譯文；保留角色名、作品名、身分設定、來源標記，不加解釋，不改寫設定。"
        case .animeReview, .mangaReview:
            return "只輸出繁體中文譯文；保留作品名、角色名、劇透標記與評論語氣，不加解釋，不改寫評論內容。"
        }
    }

    var promptTitle: String {
        switch self {
        case .animeWork:
            return "翻譯動畫簡介："
        case .mangaWork:
            return "翻譯漫畫簡介："
        case .animeEpisode:
            return "翻譯單集簡介："
        case .characterProfile:
            return "翻譯角色介紹："
        case .animeReview:
            return "翻譯動畫評論："
        case .mangaReview:
            return "翻譯漫畫評論："
        }
    }

    var maximumResponseTokens: Int {
        switch self {
        case .animeWork:
            return 900
        case .mangaWork:
            return 900
        case .animeEpisode:
            return 700
        case .characterProfile:
            return 700
        case .animeReview, .mangaReview:
            return 1200
        }
    }
}
