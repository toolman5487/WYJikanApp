//
//  CharacterRoleFormatting.swift
//  WYJikanApp
//

import Foundation

nonisolated enum CharacterRoleFormatting {

    static func localizedName(for rawValue: String?) -> String? {
        guard var rawValue = DisplayTextFormatting.nonEmpty(rawValue) else {
            return nil
        }

        if rawValue.lowercased().hasPrefix("add ") {
            rawValue.removeFirst(4)
        }

        switch rawValue.lowercased() {
        case "main":
            return "主角"
        case "supporting":
            return "配角"
        default:
            return rawValue
        }
    }
}
