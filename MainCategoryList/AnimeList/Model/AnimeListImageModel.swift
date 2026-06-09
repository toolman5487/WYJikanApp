//
//  AnimeListImageModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Images

nonisolated struct AnimeListImagesDTO: Codable, Hashable, Sendable {
    let jpg: AnimeListImageURLDTO?
    let webp: AnimeListImageURLDTO?
}

nonisolated struct AnimeListImageURLDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}
