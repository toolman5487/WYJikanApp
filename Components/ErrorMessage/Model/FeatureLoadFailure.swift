//
//  FeatureLoadFailure.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/12.
//

import Foundation

nonisolated struct FeatureLoadFailure: Equatable, Sendable, Error {
    let message: String

    init(message: String) {
        self.message = message
    }

    init(_ error: Error) {
        self.message = error.userFacingMessage
    }
}
