//
//  DetailSupplementarySectionErrorView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import SwiftUI

struct DetailSupplementarySectionStateView<Value, Loading: View, Content: View>: View {

    @ObservedObject private var state: DetailSupplementaryState<Value>

    let title: String
    let isEmpty: (Value) -> Bool
    let onRetry: () -> Void
    @ViewBuilder let loading: () -> Loading
    @ViewBuilder let content: (Value) -> Content

    init(
        state: DetailSupplementaryState<Value>,
        title: String,
        isEmpty: @escaping (Value) -> Bool,
        onRetry: @escaping () -> Void,
        @ViewBuilder loading: @escaping () -> Loading,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.title = title
        self.isEmpty = isEmpty
        self.onRetry = onRetry
        self.loading = loading
        self.content = content
    }

    var body: some View {
        Group {
            if state.isLoading {
                loading()
            } else if let failure = state.failure {
                DetailSupplementarySectionErrorView(
                    title: title,
                    failure: failure,
                    retryTitle: "重試",
                    onRetry: onRetry
                )
            } else if !isEmpty(state.value) {
                content(state.value)
            }
        }
    }
}

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
