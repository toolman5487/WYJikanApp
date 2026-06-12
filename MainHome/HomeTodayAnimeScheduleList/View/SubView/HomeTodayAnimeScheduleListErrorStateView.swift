//
//  HomeTodayAnimeScheduleListErrorStateView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTodayAnimeScheduleListErrorStateView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        ErrorMessageRetryCardView(
            state: ErrorMessageView.State(failure: failure),
            title: "播出表暫時讀不到",
            retryTitle: "重新載入",
            onRetry: onRetry
        )
    }
}
