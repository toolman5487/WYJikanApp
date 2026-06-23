//
//  RandomPickResponseModel.swift
//  WYJikanApp
//

import Foundation

nonisolated struct AnimeListRandomResponse: Codable, Sendable {
    let data: AnimeListRandomDTO
}

nonisolated struct MangaListRandomResponse: Codable, Sendable {
    let data: MangaListRandomDTO
}
