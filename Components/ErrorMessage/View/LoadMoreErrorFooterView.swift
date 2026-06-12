//
//  LoadMoreErrorFooterView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import SwiftUI

struct LoadMoreErrorFooterView: View {

    // MARK: - Properties

    let failure: FeatureLoadFailure
    var retryTitle: String = "重試載入更多"
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ErrorMessageView(state: ErrorMessageView.State(failure: failure))

            Button(action: onRetry) {
                Label(retryTitle, systemImage: "arrow.trianglehead.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
