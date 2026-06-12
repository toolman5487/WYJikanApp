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

// MARK: - Pagination Load More Footer

enum PaginationLoadMoreAvailablePresentation {
    case endBounceHint(
        title: String,
        subtitle: String,
        progress: CGFloat = 0,
        axis: EndBounceAxis = .vertical
    )
    case prominentButton(title: String)
}

struct PaginationLoadMoreFooterView: View {

    let state: PaginationFooterState
    var availablePresentation: PaginationLoadMoreAvailablePresentation = .endBounceHint(
        title: "載入更多",
        subtitle: "繼續往下拉展開更多"
    )
    var loadingMinHeight: CGFloat = 116
    var retryTitle: String = "重試載入更多"
    var onAvailableTap: (() -> Void)? = nil
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .available:
            availableView

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: loadingMinHeight)

        case let .error(failure):
            LoadMoreErrorFooterView(
                failure: failure,
                retryTitle: retryTitle,
                onRetry: onRetry
            )
        }
    }

    @ViewBuilder
    private var availableView: some View {
        switch availablePresentation {
        case let .endBounceHint(title, subtitle, progress, axis):
            EndBounceHintView(
                axis: axis,
                title: title,
                subtitle: subtitle,
                progress: progress
            )
            .modifier(OptionalTapGestureModifier(action: onAvailableTap))

        case let .prominentButton(title):
            Button(title) {
                onAvailableTap?()
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
        }
    }
}

private struct OptionalTapGestureModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}

struct PaginatedItemListSection<Item: Identifiable, RowContent: View>: View {

    let items: [Item]
    let loadMoreState: PaginationFooterState
    var loadMoreProgress: CGFloat = 0
    var loadMoreAvailableTitle: String = "載入更多"
    var loadMoreAvailableSubtitle: String = "繼續往下拉展開更多"
    var onLoadMoreTap: (() -> Void)? = nil
    let onRetryLoadMore: () -> Void
    @ViewBuilder let rowContent: (Item) -> RowContent

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                rowContent(item)
            }

            PaginationLoadMoreFooterView(
                state: loadMoreState,
                availablePresentation: .endBounceHint(
                    title: loadMoreAvailableTitle,
                    subtitle: loadMoreAvailableSubtitle,
                    progress: loadMoreProgress
                ),
                onAvailableTap: onLoadMoreTap,
                onRetry: onRetryLoadMore
            )
        }
    }
}
