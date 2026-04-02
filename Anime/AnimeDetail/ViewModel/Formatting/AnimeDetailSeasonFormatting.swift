//
//  AnimeDetailSeasonFormatting.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

enum AnimeDetailSeasonFormatting {

    static func chineseLabel(from raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        switch raw.lowercased() {
        case "winter": return "冬季"
        case "spring": return "春季"
        case "summer": return "夏季"
        case "fall", "autumn": return "秋季"
        default: return raw
        }
    }
}
