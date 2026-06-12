//
//  HomeTrendingAnimeListErrorStateView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListErrorStateView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        ErrorMessageRetryCardView(
            state: ErrorMessageView.State(failure: failure),
            title: "熱門榜單暫時讀不到",
            retryTitle: "重新載入",
            onRetry: onRetry
        )
    }
}
