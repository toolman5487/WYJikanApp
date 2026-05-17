//
//  AnimeDetailSectionComponents.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

enum DetailNavigationToolbarShareState {
    case loading
    case available(title: String, message: String, url: URL)
}

enum DetailNavigationToolbarReviewState {
    case loading
    case available(title: String)
}

enum DetailNavigationToolbarExternalPageState {
    case unavailable
    case available(title: String, url: URL)
}

struct DetailNavigationToolbar<ReviewDestination: View>: ToolbarContent {
    let isFavorite: Bool
    let isFavoriteActionEnabled: Bool
    let shareState: DetailNavigationToolbarShareState
    let reviewState: DetailNavigationToolbarReviewState
    let isRefreshing: Bool
    let onFavoriteTap: () -> Void
    let onRefreshTap: () -> Void
    let reviewDestination: (String) -> ReviewDestination

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            favoriteButton
        }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItemGroup(placement: .topBarTrailing) {
            shareAction
            reviewAction
            refreshButton
        }
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteTap) {
            DetailNavigationToolbarIcon(
                systemName: isFavorite ? "heart.fill" : "heart",
                tintColor: isFavoriteActionEnabled ? ThemeColor.sakura : ThemeColor.textSecondary
            )
            .frame(minWidth: 44, minHeight: 44)
        }
        .disabled(!isFavoriteActionEnabled)
    }

    @ViewBuilder
    private var shareAction: some View {
        switch shareState {
        case .loading:
            DetailNavigationToolbarIcon(
                systemName: "square.and.arrow.up",
                tintColor: ThemeColor.textSecondary
            )
        case let .available(title, message, url):
            ShareLink(
                item: url,
                subject: Text(title),
                message: Text(message)
            ) {
                DetailNavigationToolbarIcon(
                    systemName: "square.and.arrow.up",
                    tintColor: ThemeColor.sakura
                )
            }
        }
    }

    @ViewBuilder
    private var reviewAction: some View {
        switch reviewState {
        case .loading:
            DetailNavigationToolbarIcon(
                systemName: "text.bubble.fill",
                tintColor: ThemeColor.textSecondary
            )
        case let .available(title):
            NavigationLink {
                reviewDestination(title)
            } label: {
                DetailNavigationToolbarIcon(
                    systemName: "text.bubble.fill",
                    tintColor: ThemeColor.sakura
                )
            }
        }
    }

    private var refreshButton: some View {
        Button(action: onRefreshTap) {
            DetailNavigationToolbarIcon(
                systemName: "arrow.trianglehead.counterclockwise",
                tintColor: isRefreshing ? ThemeColor.textSecondary : ThemeColor.sakura
            )
            .symbolEffect(.rotate, options: .repeating, isActive: isRefreshing)
            .opacity(isRefreshing ? 0.7 : 1)
            .frame(minWidth: 44, minHeight: 44)
        }
        .disabled(isRefreshing)
    }
}

struct DetailExternalActionsToolbar: ToolbarContent {
    let shareState: DetailNavigationToolbarShareState
    let externalPageState: DetailNavigationToolbarExternalPageState

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            shareAction
            externalPageAction
        }
    }

    @ViewBuilder
    private var shareAction: some View {
        switch shareState {
        case .loading:
            DetailNavigationToolbarIcon(
                systemName: "square.and.arrow.up",
                tintColor: ThemeColor.textSecondary
            )
        case let .available(title, message, url):
            ShareLink(
                item: url,
                subject: Text(title),
                message: Text(message)
            ) {
                DetailNavigationToolbarIcon(
                    systemName: "square.and.arrow.up",
                    tintColor: ThemeColor.sakura
                )
            }
        }
    }

    @ViewBuilder
    private var externalPageAction: some View {
        switch externalPageState {
        case .unavailable:
            EmptyView()
        case let .available(title, url):
            NavigationLink {
                NavigationWebPageView(title: title, url: url)
            } label: {
                DetailNavigationToolbarIcon(
                    systemName: "safari",
                    tintColor: ThemeColor.sakura
                )
            }
        }
    }
}

private struct DetailNavigationToolbarIcon: View {
    let systemName: String
    let tintColor: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.bold))
            .foregroundStyle(tintColor)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}

struct AnimeDetailSectionCard<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .foregroundStyle(ThemeColor.sakura)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnimeDetailInfoRow: View {
    let title: String
    let value: String
    var subtitle: String?

    init(title: String, value: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
                .frame(width: 72, alignment: .leading)

            Group {
                if let subtitle, !subtitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(ThemeColor.textPrimary)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textTertiary)
                    }
                } else {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
