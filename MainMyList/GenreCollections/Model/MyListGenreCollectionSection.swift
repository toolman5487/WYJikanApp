//
//  MyListGenreCollectionSection.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

nonisolated struct MyListGenreCollectionSection: Identifiable, Sendable {
    let genreName: String
    let items: [MyListItemSnapshot]

    var id: String { genreName }
    var count: Int { items.count }
}
