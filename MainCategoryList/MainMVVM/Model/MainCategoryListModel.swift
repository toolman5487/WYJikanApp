//
//  MainCategoryListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

enum MainCategoryTopFilterState: Hashable, Sendable {
    case hidden
    case menu(MainCategoryTopFilterMenu)
}

struct MainCategoryTopFilterMenu: Hashable, Sendable {
    let accessibilityLabel: String
    let accessibilityValue: String
    let selectionIdentifier: String
    let options: [MainCategoryTopFilterOption]
}

enum MainCategoryTopFilterOption: Hashable, Identifiable, Sendable {
    case people(PeopleListSort)
    case character(CharacterListSort)

    var id: Self { self }

    var title: String {
        switch self {
        case .people(let sort):
            return sort.title
        case .character(let sort):
            return sort.title
        }
    }

    var systemImageName: String {
        switch self {
        case .people(let sort):
            return sort.systemImageName
        case .character(let sort):
            return sort.systemImageName
        }
    }
}

