//
//  FeatureEmptyState.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import Foundation

nonisolated struct FeatureEmptyState: Equatable, Sendable {
    let kind: ErrorMessageKind
    let message: String
    var title: String? = nil

    static func emptyCollection(title: String? = nil, message: String) -> Self {
        Self(kind: .emptyCollection, message: message, title: title)
    }

    static func filteredEmpty(title: String? = nil, message: String) -> Self {
        Self(kind: .filteredEmpty, message: message, title: title)
    }

    static func noSearchResults(title: String? = nil, message: String) -> Self {
        Self(kind: .noSearchResults, message: message, title: title)
    }
}
