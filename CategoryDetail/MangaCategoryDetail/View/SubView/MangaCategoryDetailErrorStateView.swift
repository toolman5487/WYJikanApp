//
//  MangaCategoryDetailErrorStateView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailErrorStateView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        ErrorMessageRetryCardView(
            state: ErrorMessageView.State(failure: failure),
            title: "這個分類暫時打不開",
            retryTitle: "重新載入",
            onRetry: onRetry
        )
    }
}
