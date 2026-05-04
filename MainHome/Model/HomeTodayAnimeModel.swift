//
//  HomeTodayAnimeModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Presentation

struct HomeTodayAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let imageURL: URL
}
