//
//  VoiceLanguageFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum VoiceLanguageFormatting {

    static func localizedName(for rawValue: String?) -> String? {
        guard let rawValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        switch rawValue.lowercased() {
        case "japanese":
            return "日語"
        case "english":
            return "英語"
        case "mandarin":
            return "華語"
        case "korean":
            return "韓語"
        case "cantonese":
            return "粵語"
        case "french":
            return "法語"
        case "german":
            return "德語"
        case "italian":
            return "義大利語"
        case "spanish":
            return "西班牙語"
        case "portuguese", "brazilian":
            return "葡萄牙語"
        default:
            return rawValue
        }
    }
}
