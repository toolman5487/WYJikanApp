//
//  MyListFormatDisplay.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated enum MyListFormatDisplay {
    static func displayItem(
        type: String?,
        mediaKind: MyListMediaKind
    ) -> (title: String, iconName: String)? {
        let kind: MediaTypeFormatting.MediaKind = switch mediaKind {
        case .anime:
            .anime
        case .manga:
            .manga
        }

        guard let title = MediaTypeFormatting.localizedName(for: type, kind: kind) else {
            return nil
        }

        return (title, iconName(forFormatTitle: title))
    }

    static func iconName(forFormatTitle title: String) -> String {
        switch title {
        case "電視動畫":
            return "tv.fill"
        case "劇場版", "電影":
            return "film.fill"
        case "OVA":
            return "opticaldisc.fill"
        case "ONA":
            return "play.rectangle.on.rectangle.fill"
        case "特別篇", "電視特別篇":
            return "sparkles.tv.fill"
        case "音樂":
            return "music.note"
        case "漫畫":
            return "book.closed.fill"
        case "韓漫":
            return "book.pages.fill"
        case "條漫／華漫", "華語漫畫":
            return "books.vertical.fill"
        case "小說":
            return "text.book.closed.fill"
        case "輕小說":
            return "book.fill"
        case "單篇", "短篇":
            return "doc.text.fill"
        case "同人誌":
            return "person.2.fill"
        default:
            return "square.grid.2x2.fill"
        }
    }
}
