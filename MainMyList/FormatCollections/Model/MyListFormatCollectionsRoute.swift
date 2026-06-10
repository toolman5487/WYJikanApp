//
//  MyListFormatCollectionsRoute.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import Foundation

struct MyListFormatCollectionsRoute: Identifiable, Hashable {
    let scopeTitle: String
    let formatSections: [MyListFormatCollectionSection]
    let selectedFormatTitle: String

    var id: String { "\(scopeTitle)-\(selectedFormatTitle)" }

    static func == (lhs: MyListFormatCollectionsRoute, rhs: MyListFormatCollectionsRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
