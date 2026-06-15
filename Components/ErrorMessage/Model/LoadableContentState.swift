//
//  LoadableContentState.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

nonisolated enum LoadableContentState<Content> {
    case loading
    case error(FeatureLoadFailure)
    case empty
    case content(Content)

    var content: Content? {
        switch self {
        case .content(let content):
            return content
        case .loading, .error, .empty:
            return nil
        }
    }

    var hasContent: Bool {
        if case .content = self { return true }
        return false
    }
}

extension LoadableContentState: Equatable where Content: Equatable {}

extension LoadableContentState: Sendable where Content: Sendable {}

extension LoadableContentState where Content: RangeReplaceableCollection {
    var items: Content {
        switch self {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return Content()
        }
    }
}
