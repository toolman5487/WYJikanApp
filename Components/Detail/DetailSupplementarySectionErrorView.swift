//
//  DetailSupplementarySectionErrorView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import SwiftUI

struct DetailSupplementarySectionErrorView: View {

    // MARK: - Properties

    let title: String
    let failure: FeatureLoadFailure
    var retryTitle: String = "重試"
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        AnimeDetailSectionCard(title) {
            VStack(alignment: .leading, spacing: 12) {
                ErrorMessageView(state: ErrorMessageView.State(failure: failure))

                Button(retryTitle, action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
