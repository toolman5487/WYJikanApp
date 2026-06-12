//
//  MainNewsHeaderView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsHeaderView: View {
    let content: MainNewsHeaderContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.title)
                .font(.largeTitle.weight(.black))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(content.subtitle)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if content.countText != nil || content.updatedText != nil {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        metadataChips
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        metadataChips
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let countText = content.countText {
            chip(countText, systemImageName: "doc.text")
        }

        if let updatedText = content.updatedText {
            chip(updatedText, systemImageName: "clock")
        }
    }

    private func chip(
        _ text: String,
        systemImageName: String
    ) -> some View {
        Label(text, systemImage: systemImageName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(ThemeColor.sakura.opacity(0.32))
            .clipShape(Capsule())
    }
}
