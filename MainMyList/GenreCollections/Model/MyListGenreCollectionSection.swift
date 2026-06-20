//
//  MyListGenreCollectionSection.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

struct MyListGenreCollectionSection: Identifiable {
    let genreName: String
    let items: [MyListItemSnapshot]

    var id: String { genreName }
    var count: Int { items.count }
}
