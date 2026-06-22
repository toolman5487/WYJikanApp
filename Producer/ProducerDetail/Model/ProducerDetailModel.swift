//
//  ProducerDetailModel.swift
//  WYJikanApp
//

import Foundation

// MARK: - Response

nonisolated struct ProducerDetailResponse: Codable, Sendable {
    let data: ProducerDetailDTO
}

// MARK: - Producer Detail

nonisolated struct ProducerDetailDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let titles: [ProducerTitleDTO]?
    let images: ProducerImagesDTO?
    let favorites: Int?
    let established: String?
    let about: String?
    let count: Int?

    var id: Int { malId }
}

// MARK: - Titles

nonisolated struct ProducerTitleDTO: Codable, Hashable, Sendable {
    let type: String?
    let title: String?
}

// MARK: - Images

nonisolated struct ProducerImagesDTO: Codable, Hashable, Sendable {
    let jpg: ProducerImageDTO?
}

nonisolated struct ProducerImageDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
}
