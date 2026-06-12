//
//  FeatureLoadFailure.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/12.
//

import Foundation

nonisolated struct FeatureLoadFailure: Equatable, Sendable, Error {
    let message: String
    let kind: ErrorMessageKind

    init(message: String, kind: ErrorMessageKind? = nil) {
        self.message = message
        self.kind = kind ?? ErrorMessageKind.resolving(message: message)
    }

    init(message: String, context: ErrorMessageLoadContext) {
        self.message = message
        self.kind = ErrorMessageKind.resolving(message: message, context: context)
    }

    init(_ error: Error) {
        self.message = error.userFacingMessage
        self.kind = ErrorMessageKind.resolving(from: error)
    }

    static func loadMore(message: String = "載入更多失敗") -> Self {
        Self(message: message, kind: .loadMoreFailed)
    }
}
