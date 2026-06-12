//
//  ErrorMessageRetryCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/12.
//

import SwiftUI

struct ErrorMessageRetryCardView: View {

    // MARK: - Properties

    let state: ErrorMessageView.State
    var title: String?
    let retryTitle: String
    let onRetry: () -> Void
    var minHeight: CGFloat = 220
    var alignment: HorizontalAlignment = .center

    // MARK: - Body

    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            if let title {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: titleAlignment)
            }

            ErrorMessageView(state: state)

            Button(retryTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: frameAlignment)
        .padding(24)
        .background(Color(.secondarySystemBackground))
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

    private var frameAlignment: Alignment {
        alignment == .center ? .center : .leading
    }
}
