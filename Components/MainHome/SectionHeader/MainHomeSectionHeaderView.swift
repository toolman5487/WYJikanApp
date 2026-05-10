//
//  MainHomeSectionHeaderView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/10.
//

import SwiftUI

struct GlassSectionHeaderView: View {
    enum State {
        case plain
        case accessoryText(String)
        case navigable(action: () -> Void)
    }

    let title: String
    let state: State

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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    init(title: String, state: State = .plain) {
        self.title = title
        self.state = state
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch state {
        case .plain:
            EmptyView()
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
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .tracking(0.8)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
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
