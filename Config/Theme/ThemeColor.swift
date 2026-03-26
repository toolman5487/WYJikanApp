//
//  ThemeColor.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

import SwiftUI
import UIKit

// MARK: - Theme Color Roles

enum ThemeColor {
    static let sakuraHex = "#FF4FA3"

    static let sakura: Color = Color(UIColor(hex: sakuraHex) ?? .systemPink)
    static let primary: Color = sakura
    static let accent: Color = sakura

    static let sakuraGlass: Color = Color(UIColor(hex: sakuraHex, alpha: 0.20) ?? .systemPink.withAlphaComponent(0.20))
    static let sakuraGlassStrong: Color = Color(UIColor(hex: sakuraHex, alpha: 0.35) ?? .systemPink.withAlphaComponent(0.35))

    static let textPrimary: Color = Color(.label)
    static let textSecondary: Color = Color(.secondaryLabel)
    static let textTertiary: Color = Color(.systemPink).opacity(0.65)
    static let textQuaternary: Color = Color(.systemPink).opacity(0.45)

    static let separator: Color = Color(.separator)
}
