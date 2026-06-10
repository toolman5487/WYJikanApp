//
//  MyListGenreCollectionsRoute.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import Foundation

struct MyListGenreCollectionsRoute: Identifiable, Hashable {
    let scopeTitle: String
    let genreSections: [MyListGenreCollectionSection]
    let selectedGenreName: String

    var id: String { "\(scopeTitle)-\(selectedGenreName)" }

    static func == (lhs: MyListGenreCollectionsRoute, rhs: MyListGenreCollectionsRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
