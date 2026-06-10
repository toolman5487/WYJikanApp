//
//  MyListGenreCollectionsSectionBuilder.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Foundation

enum MyListGenreCollectionsSectionBuilder {
    static func makeSections(
        from items: [MyListCollectionItem]
    ) -> [MyListGenreCollectionSection] {
        var groupedItems: [String: [MyListCollectionItem]] = [:]

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
