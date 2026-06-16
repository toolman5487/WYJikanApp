//
//  MyListFormatCollectionsSectionBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import Foundation

// MARK: - MyListFormatCollectionsSectionBuilder

enum MyListFormatCollectionsSectionBuilder {
    static func makeSections(
        from items: [MyListCollectionItem]
    ) -> [MyListFormatCollectionSection] {
        var groupedItems: [String: [MyListCollectionItem]] = [:]

        for item in items {
            guard let format = MyListFormatDisplay.displayItem(
                type: item.type,
                mediaKind: item.mediaKind
            ) else {
                continue
            }

            groupedItems[format.title, default: []].append(item)
        }

        return groupedItems
            .map { title, items in
                MyListFormatCollectionSection(
                    title: title,
                    iconName: MyListFormatDisplay.iconName(forFormatTitle: title),
                    items: items.sorted { lhs, rhs in lhs.addedAt > rhs.addedAt }
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
    }
}
