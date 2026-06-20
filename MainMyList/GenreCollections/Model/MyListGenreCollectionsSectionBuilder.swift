//
//  MyListGenreCollectionsSectionBuilder.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

// MARK: - MyListGenreCollectionsSectionBuilder

enum MyListGenreCollectionsSectionBuilder {
    static func makeSections(
        from items: [MyListItemSnapshot]
    ) -> [MyListGenreCollectionSection] {
        var groupedItems: [String: [MyListItemSnapshot]] = [:]

        for item in items {
            for genreName in item.genreNames {
                groupedItems[genreName, default: []].append(item)
            }
        }

        return groupedItems
            .map { genreName, items in
                MyListGenreCollectionSection(
                    genreName: genreName,
                    items: items.sorted { lhs, rhs in lhs.addedAt > rhs.addedAt }
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.genreName.localizedStandardCompare(rhs.genreName) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
    }
}
