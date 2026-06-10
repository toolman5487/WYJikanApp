//
//  MyListFormatDisplay.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

enum MyListFormatDisplay {
    static func displayItem(
        type: String?,
        mediaKind: MyListMediaKind
    ) -> (title: String, iconName: String)? {
        guard let type else { return nil }
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedType.isEmpty else { return nil }

        switch mediaKind {
        case .anime:
            return animeDisplayItem(type: normalizedType)
        case .manga:
            return mangaDisplayItem(type: normalizedType)
        }
    }

    static func iconName(forFormatTitle title: String) -> String {
        switch title {
        case "電視動畫":
            return "tv.fill"
        case "電影":
            return "film.fill"
        case "OVA":
            return "opticaldisc.fill"
        case "ONA":
            return "play.rectangle.on.rectangle.fill"
        case "特別篇":
            return "sparkles.tv.fill"
        case "音樂":
            return "music.note"
        case "漫畫":
            return "book.closed.fill"
        case "韓漫":
            return "book.pages.fill"
        case "華語漫畫":
            return "books.vertical.fill"
        case "小說":
            return "text.book.closed.fill"
        case "輕小說":
            return "book.fill"
        case "短篇":
            return "doc.text.fill"
        case "同人誌":
            return "person.2.fill"
        default:
            return "square.grid.2x2.fill"
        }
    }

    private static func animeDisplayItem(type: String) -> (title: String, iconName: String) {
        switch type.lowercased() {
        case "tv":
            return ("電視動畫", "tv.fill")
        case "movie":
            return ("電影", "film.fill")
        case "ova":
            return ("OVA", "opticaldisc.fill")
        case "ona":
            return ("ONA", "play.rectangle.on.rectangle.fill")
        case "special", "tv special":
            return ("特別篇", "sparkles.tv.fill")
        case "music":
            return ("音樂", "music.note")
        default:
            return (type, MyListMediaKind.anime.iconName)
        }
    }

    private static func mangaDisplayItem(type: String) -> (title: String, iconName: String) {
        switch type.lowercased() {
        case "manga":
            return ("漫畫", "book.closed.fill")
        case "manhwa":
            return ("韓漫", "book.pages.fill")
        case "manhua":
            return ("華語漫畫", "books.vertical.fill")
        case "novel":
            return ("小說", "text.book.closed.fill")
        case "light novel":
            return ("輕小說", "book.fill")
        case "one-shot":
            return ("短篇", "doc.text.fill")
        case "doujinshi":
            return ("同人誌", "person.2.fill")
        default:
            return (type, MyListMediaKind.manga.iconName)
        }
    }
}
