//
//  SettingSectionViews.swift
//  WYJikanApp
//

import SwiftUI

// MARK: - Action Label

struct SettingActionLabel: View {
    let title: String
    let systemImage: String
    let state: SettingActionState

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(ThemeColor.textPrimary)
            Spacer()
            accessory
        }
    }

    @ViewBuilder
    private var accessory: some View {
        switch state {
        case .idle:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(ThemeColor.textPrimary)
        }
    }
}

// MARK: - Value Accessory

struct SettingValueAccessory: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(ThemeColor.textSecondary)
    }
}
