//
//  AnimeDetailMediaKind.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

enum AnimeDetailMediaKind: Equatable {

    case tv
    case movie
    case ova
    case ona
    case special
    case music
    case other(raw: String)

    init(anime: AnimeDetailDTO) {
        guard let raw = anime.type?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            self = .other(raw: "")
            return
        }
        switch raw.uppercased() {
        case "TV":
            self = .tv
        case "MOVIE":
            self = .movie
        case "OVA":
            self = .ova
        case "ONA":
            self = .ona
        case "SPECIAL":
            self = .special
        case "MUSIC":
            self = .music
        default:
            self = .other(raw: raw)
        }
    }

    var displayName: String {
        switch self {
        case .tv:
            return "電視動畫"
        case .movie:
            return "劇場版"
        case .ova:
            return "OVA"
        case .ona:
            return "網路動畫"
        case .special:
            return "特別篇"
        case .music:
            return "音樂"
        case .other(let raw):
            return raw.isEmpty ? "-" : raw
        }
    }
}
