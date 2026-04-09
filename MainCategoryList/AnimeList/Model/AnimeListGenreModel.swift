//
//  AnimeListGenreModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Genre

struct AnimeListGenreDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

// MARK: - Genre Section

struct AnimeGenreSection: Identifiable, Hashable {
    let genre: AnimeListGenreDTO
    let items: [AnimeListRandomDTO]

    var id: Int { genre.id }
}
