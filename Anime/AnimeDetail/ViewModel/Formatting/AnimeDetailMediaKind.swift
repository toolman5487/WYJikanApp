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
            return MediaTypeFormatting.localizedName(for: "TV", kind: .anime) ?? "-"
        case .movie:
            return MediaTypeFormatting.localizedName(for: "MOVIE", kind: .anime) ?? "-"
        case .ova:
            return MediaTypeFormatting.localizedName(for: "OVA", kind: .anime) ?? "-"
        case .ona:
            return MediaTypeFormatting.localizedName(for: "ONA", kind: .anime) ?? "-"
        case .special:
            return MediaTypeFormatting.localizedName(for: "SPECIAL", kind: .anime) ?? "-"
        case .music:
            return MediaTypeFormatting.localizedName(for: "MUSIC", kind: .anime) ?? "-"
        case .other(let raw):
            return raw.isEmpty ? "-" : raw
        }
    }
}
