//
//  ErrorMessageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct ErrorMessageView: View {
    enum State: Equatable {
        case network(String)
        case noSearchResults(String)
        case emptyCollection(String)
        case unavailable(String)
    }

    let state: State
    var height: CGFloat?

    init(state: State, height: CGFloat? = nil) {
        self.state = state
        self.height = height
    }

    var body: some View {
        Group {
            if let height {
                content.frame(height: height)
            } else {
                content
            }
        }
    }

    private var messageText: String {
        switch state {
        case .network(let text),
             .noSearchResults(let text),
             .emptyCollection(let text),
             .unavailable(let text):
            return text
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 56, height: 56)

                Image(systemName: iconSystemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            Text(messageText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(messageText)
    }

    private var iconSystemName: String {
        switch state {
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

    private var iconColor: Color {
        switch state {
        case .network:
            Color.red
        case .noSearchResults, .unavailable:
            Color.yellow
        case .emptyCollection:
            ThemeColor.textTertiary
        }
    }
}

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
