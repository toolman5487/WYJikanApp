//
//  MainHomeSectionHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/10.
//

import SwiftUI

// MARK: - GlassSectionHeaderView

struct GlassSectionHeaderView: View {

    // MARK: - Types

    enum State {
        case plain
        case accessoryText(String)
        case navigable(action: () -> Void)
    }

    // MARK: - Properties

    let title: String
    let state: State
    let showsDisclosureIndicator: Bool
    let outerVerticalPadding: CGFloat

    // MARK: - Lifecycle

    init(
        title: String,
        state: State = .plain,
        showsDisclosureIndicator: Bool = false,
        outerVerticalPadding: CGFloat = 12
    ) {
        self.title = title
        self.state = state
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.outerVerticalPadding = outerVerticalPadding
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch state {
            case .plain, .accessoryText:
                headerContent
            case let .navigable(action):
                Button(action: action) {
                    headerContent
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, outerVerticalPadding)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var trailingContent: some View {
        switch state {
        case .plain:
            if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(ThemeColor.sakura.opacity(0.78))
            } else {
                EmptyView()
            }
        case let .accessoryText(text):
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
        case .navigable:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(ThemeColor.sakura.opacity(0.78))
        }
    }

    private var headerContent: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline.weight(.black))
                .tracking(0.4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ThemeColor.sakura,
                            ThemeColor.sakura.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            trailingContent

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            ThemeColor.sakura.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: ThemeColor.sakura.opacity(0.10), radius: 16, y: 8)
    }
}
