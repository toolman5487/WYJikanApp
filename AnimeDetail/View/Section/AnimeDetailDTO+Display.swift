//
//  AnimeDetailDTO+Display.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

extension AnimeDetailDTO {
    var displayTitle: String {
        titleJapanese ?? titleEnglish ?? title ?? "動畫"
    }
    
    var posterURL: URL? {
        let urlString =
        images?.webp?.largeImageUrl ??
        images?.jpg?.largeImageUrl ??
        images?.webp?.imageUrl ??
        images?.jpg?.imageUrl
        guard let urlString else { return nil }
        return URL(string: urlString)
    }
    
    var seasonText: String {
        let season = season?.capitalized
        let year = year.map(String.init)
        
        switch (season, year) {
        case let (s?, y?):
            return "\(y) \(s)"
        case let (s?, nil):
            return s
        case let (nil, y?):
            return y
        default:
            return "-"
        }
    }
    
    func joinedNames(from entities: [AnimeRelatedEntityDTO]?) -> String {
        guard let entities, !entities.isEmpty else { return "-" }
        let names = entities.compactMap(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "-" : names.joined(separator: "、")
    }
    
    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
