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
        case serverError(String)
        case timeout(String)
        case noSearchResults(String)
        case emptyCollection(String)
        case filteredEmpty(String)
        case notFound(String)
        case loadMoreFailed(String)
        case unavailable(String)
        case permissionDenied(String)
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

// MARK: - State Mapping

extension ErrorMessageView.State {
    init(kind: ErrorMessageKind, message: String) {
        switch kind {
        case .network:
            self = .network(message)
        case .serverError:
            self = .serverError(message)
        case .timeout:
            self = .timeout(message)
        case .noSearchResults:
            self = .noSearchResults(message)
        case .emptyCollection:
            self = .emptyCollection(message)
        case .filteredEmpty:
            self = .filteredEmpty(message)
        case .notFound:
            self = .notFound(message)
        case .loadMoreFailed:
            self = .loadMoreFailed(message)
        case .unavailable:
            self = .unavailable(message)
        case .permissionDenied:
            self = .permissionDenied(message)
        }
    }

    init(failure: FeatureLoadFailure) {
        self.init(kind: failure.kind, message: failure.message)
    }
}

// MARK: - State Presentation

private extension ErrorMessageView.State {
    var message: String {
        switch self {
        case .network(let text),
             .serverError(let text),
             .timeout(let text),
             .noSearchResults(let text),
             .emptyCollection(let text),
             .filteredEmpty(let text),
             .notFound(let text),
             .loadMoreFailed(let text),
             .unavailable(let text),
             .permissionDenied(let text):
            return text
        }
    }

    var iconSystemName: String {
        switch self {
        case .network:
            "wifi.exclamationmark"
        case .serverError:
            "server.rack"
        case .timeout:
            "clock.badge.exclamationmark"
        case .noSearchResults:
            "magnifyingglass"
        case .emptyCollection:
            "tray.fill"
        case .filteredEmpty:
            "line.3.horizontal.decrease.circle"
        case .notFound:
            "doc.questionmark"
        case .loadMoreFailed:
            "arrow.down.circle"
        case .unavailable:
            "square.3.layers.3d.down.right.slash"
        case .permissionDenied:
            "lock.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .network:
            Color.red
        case .serverError, .timeout:
            Color.orange
        case .noSearchResults, .unavailable, .loadMoreFailed:
            Color.yellow
        case .emptyCollection, .filteredEmpty, .notFound:
            ThemeColor.textTertiary
        case .permissionDenied:
            ThemeColor.sakura
        }
    }
}

// MARK: - Preview

#Preview("網路錯誤") {
    ErrorMessageView(state: .network("網路連線不穩，請確認連線後再試。"), height: 200)
}

#Preview("伺服器錯誤") {
    ErrorMessageView(state: .serverError("伺服器暫時無法回應，請稍後再試。"), height: 200)
}

#Preview("連線逾時") {
    ErrorMessageView(state: .timeout("連線逾時，請稍後再試。"), height: 200)
}

#Preview("查無結果") {
    ErrorMessageView(state: .noSearchResults("找不到符合條件的結果"), height: 200)
}

#Preview("空資料") {
    ErrorMessageView(state: .emptyCollection("尚無可顯示的項目"), height: 200)
}

#Preview("篩選無結果") {
    ErrorMessageView(state: .filteredEmpty("此篩選條件下沒有符合的項目"), height: 200)
}

#Preview("找不到內容") {
    ErrorMessageView(state: .notFound("找不到這筆資料"), height: 200)
}

#Preview("載入更多失敗") {
    ErrorMessageView(state: .loadMoreFailed("載入更多失敗，請稍後再試"), height: 200)
}

#Preview("不可用") {
    ErrorMessageView(state: .unavailable("目前無法使用這項功能"), height: 200)
}

#Preview("權限不足") {
    ErrorMessageView(state: .permissionDenied("請在設定中開啟通知權限"), height: 200)
}
