//
//  ErrorMessageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct ErrorMessageView: View {

    // MARK: - Types

    enum State: Equatable {
        case network(String)
        case noSearchResults(String)
        case emptyCollection(String)
        case unavailable(String)
    }

    // MARK: - Properties

    let state: State
    var height: CGFloat?

    // MARK: - Lifecycle

    init(state: State, height: CGFloat? = nil) {
        self.state = state
        self.height = height
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let height {
                content.frame(height: height)
            } else {
                content
            }
        }
    }

    // MARK: - Private Views

    private var content: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(state.iconColor.opacity(0.14))
                    .frame(width: 56, height: 56)

                Image(systemName: state.iconSystemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(state.iconColor)
            }

            Text(state.message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - State Presentation

private extension ErrorMessageView.State {
    var message: String {
        switch self {
        case .network(let text),
             .noSearchResults(let text),
             .emptyCollection(let text),
             .unavailable(let text):
            return text
        }
    }

    var iconSystemName: String {
        switch self {
        case .network:
            "wifi.exclamationmark"
        case .noSearchResults:
            "magnifyingglass"
        case .emptyCollection:
            "tray.fill"
        case .unavailable:
            "square.3.layers.3d.down.right.slash"
        }
    }

    var iconColor: Color {
        switch self {
        case .network:
            Color.red
        case .noSearchResults, .unavailable:
            Color.yellow
        case .emptyCollection:
            ThemeColor.textTertiary
        }
    }
}

// MARK: - Preview

#Preview("網路錯誤") {
    ErrorMessageView(state: .network("Failed to load data."), height: 200)
}

#Preview("查無結果") {
    ErrorMessageView(state: .noSearchResults("找不到符合條件的結果"), height: 200)
}

#Preview("空資料") {
    ErrorMessageView(state: .emptyCollection("尚無可顯示的項目"), height: 200)
}

#Preview("不可用") {
    ErrorMessageView(state: .unavailable("目前無法使用這項功能"), height: 200)
}
