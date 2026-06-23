//
//  DetailCopyableTextStyle.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

enum DetailCopyableTextStyle {
    case primary
    case secondary
    case info

    var font: Font {
        switch self {
        case .primary:
            return .title2.weight(.bold)
        case .secondary:
            return .subheadline
        case .info:
            return .subheadline
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .primary:
            return ThemeColor.textPrimary
        case .info:
            return ThemeColor.textPrimary
        case .secondary:
            return ThemeColor.textSecondary
        }
    }
}
