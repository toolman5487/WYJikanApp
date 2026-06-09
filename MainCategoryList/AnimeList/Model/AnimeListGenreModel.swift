//
//  AnimeListGenreModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Genre

nonisolated struct AnimeListGenreDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

// MARK: - Genre Section

nonisolated struct AnimeGenreSection: Identifiable, Hashable, Sendable {
    let genre: AnimeListGenreDTO
    let items: [AnimeListRandomDTO]

    var id: Int { genre.id }
}
