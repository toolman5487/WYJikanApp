//
//  AnimeListImageModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Images

struct AnimeListImagesDTO: Codable, Hashable {
    let jpg: AnimeListImageURLDTO?
    let webp: AnimeListImageURLDTO?
}

struct AnimeListImageURLDTO: Codable, Hashable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}
