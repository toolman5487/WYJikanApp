//
//  DisplayNumberFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum DisplayNumberFormatting {

    static func decimal(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }

    static func compact(
        _ value: Int,
        fractionDigits: Int = 1,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        value.formatted(
            .number
                .notation(.compactName)
                .precision(.fractionLength(0...max(0, fractionDigits)))
                .locale(locale)
        )
    }

    static func fixed(
        _ value: Double,
        fractionDigits: Int,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(max(0, fractionDigits)))
                .locale(locale)
        )
    }
}
