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
    var value: String?

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
            HStack(spacing: 8) {
                if let value {
                    Text(value)
                        .foregroundStyle(ThemeColor.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(ThemeColor.textPrimary)
        }
    }

    init(
        title: String,
        systemImage: String,
        state: SettingActionState,
        value: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.state = state
        self.value = value
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
