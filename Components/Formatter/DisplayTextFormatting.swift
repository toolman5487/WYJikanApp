//
//  DisplayTextFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum DisplayTextFormatting {

    static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    static func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(nonEmpty).first
    }

    static func preferred(
        _ values: [String?],
        fallback: String
    ) -> String {
        values.compactMap(nonEmpty).first ?? fallback
    }
}
