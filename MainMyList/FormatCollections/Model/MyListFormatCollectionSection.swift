//
//  MyListFormatCollectionSection.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import Foundation

nonisolated struct MyListFormatCollectionSection: Identifiable, Sendable {
    let title: String
    let iconName: String
    let items: [MyListItemSnapshot]

    var id: String { title }
    var count: Int { items.count }
}
