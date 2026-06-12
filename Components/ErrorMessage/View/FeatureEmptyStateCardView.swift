//
//  FeatureEmptyStateCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import SwiftUI

struct FeatureEmptyStateCardView: View {

    // MARK: - Properties

    let emptyState: FeatureEmptyState
    var minHeight: CGFloat = 220
    var alignment: HorizontalAlignment = .center

    // MARK: - Body

    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            if let title = emptyState.title {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .multilineTextAlignment(titleTextAlignment)
                    .frame(maxWidth: .infinity, alignment: titleAlignment)
            }

            ErrorMessageView(
                state: ErrorMessageView.State(
                    kind: emptyState.kind,
                    message: emptyState.message
                )
            )
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: frameAlignment)
        .padding(24)
        .background(.clear)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Private Properties

    private var titleFont: Font {
        alignment == .center ? .title3.weight(.bold) : .headline
    }

    private var cornerRadius: CGFloat {
        alignment == .center ? 20 : 16
    }

    private var titleAlignment: Alignment {
        alignment == .center ? .center : .leading
    }

    private var titleTextAlignment: TextAlignment {
        alignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        alignment == .center ? .center : .leading
    }
}

struct FeatureEmptyStateInlineView: View {

    // MARK: - Properties

    let emptyState: FeatureEmptyState
    var height: CGFloat?

    // MARK: - Body

    var body: some View {
        ErrorMessageView(
            state: ErrorMessageView.State(
                kind: emptyState.kind,
                message: emptyState.message
            ),
            height: height
        )
    }
}
