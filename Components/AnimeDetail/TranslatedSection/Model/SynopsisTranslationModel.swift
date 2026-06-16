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
            return """
            你是動漫作品簡介翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
            保留角色名、作品專有名詞與括號中的來源標記原意，語氣自然但不要改寫劇情。
            """
        case .mangaWork:
            return """
            你是漫畫作品簡介翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
            保留角色名、作品專有名詞與括號中的來源標記原意，語氣自然但不要改寫劇情。
            """
        case .animeEpisode:
            return """
            你是動畫單集劇情簡介翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
            保留角色名、作品專有名詞、集數資訊與括號中的來源標記原意，語氣自然但不要改寫劇情。
            """
        case .characterProfile:
            return """
            你是動漫角色介紹翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
            保留角色名、作品專有名詞、身分設定與括號中的來源標記原意，語氣自然但不要改寫角色設定。
            """
        }
    }

    var promptTitle: String {
        switch self {
        case .animeWork:
            return "請將以下英文動畫劇情簡介翻譯成繁體中文："
        case .mangaWork:
            return "請將以下英文漫畫劇情簡介翻譯成繁體中文："
        case .animeEpisode:
            return "請將以下英文動畫單集劇情簡介翻譯成繁體中文："
        case .characterProfile:
            return "請將以下英文動漫角色介紹翻譯成繁體中文："
        }
    }
}
