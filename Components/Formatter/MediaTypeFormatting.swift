//
//  MediaTypeFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum MediaTypeFormatting {
    nonisolated enum MediaKind: Sendable {
        case anime
        case manga
    }

    static func localizedName(
        for rawValue: String?,
        kind: MediaKind
    ) -> String? {
        guard let trimmedValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        switch kind {
        case .anime:
            switch trimmedValue.uppercased() {
            case "TV":
                return "電視動畫"
            case "MOVIE":
                return "劇場版"
            case "OVA":
                return "OVA"
            case "ONA":
                return "ONA"
            case "SPECIAL":
                return "特別篇"
            case "TV SPECIAL":
                return "特別篇"
            case "MUSIC":
                return "音樂"
            case "CM":
                return "廣告"
            case "PV":
                return "宣傳片"
            default:
                return trimmedValue
            }

        case .manga:
            switch normalizedMangaType(trimmedValue) {
            case "manga":
                return "漫畫"
            case "novel":
                return "小說"
            case "lightnovel":
                return "輕小說"
            case "oneshot":
                return "單篇"
            case "doujinshi":
                return "同人誌"
            case "doujin":
                return "同人誌"
            case "manhwa":
                return "韓漫"
            case "manhua":
                return "條漫／華漫"
            case "oel":
                return "OEL"
            default:
                return trimmedValue
            }
        }
    }

    private static func normalizedMangaType(_ rawValue: String) -> String {
        rawValue
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z]",
                with: "",
                options: .regularExpression
            )
    }
}
