//
//  MainNewsErrorStateView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsErrorStateView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        ErrorMessageRetryCardView(
            state: ErrorMessageView.State(failure: failure),
            title: "新聞暫時讀不到",
            retryTitle: "重新載入",
            onRetry: onRetry
        )
    }
}
