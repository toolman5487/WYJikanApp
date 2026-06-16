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
        case .idle, .failed:
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
        }
    }

    var maximumResponseTokens: Int {
        switch self {
        case .animeWork, .mangaWork:
            return 900
        case .animeEpisode, .characterProfile:
            return 700
        }
    }
}
