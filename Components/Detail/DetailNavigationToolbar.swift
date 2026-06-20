//
//  DetailNavigationToolbar.swift
//  WYJikanApp
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

enum DetailNavigationToolbarBroadcastReminderState: Equatable {
    case hidden
    case off
    case on
}

enum DetailNavigationToolbarLayoutStyle: Equatable {
    case expanded
    case compact
}

enum DetailNavigationToolbarPersistenceActionState: Equatable {
    case loading
    case available
    case unavailable

    var isEnabled: Bool {
        self != .loading
    }

    var tintColor: Color {
        switch self {
        case .available:
            return ThemeColor.sakura
        case .loading, .unavailable:
            return ThemeColor.textSecondary
        }
    }
}

struct DetailNavigationToolbarConfiguration: Equatable {
    let broadcastReminderState: DetailNavigationToolbarBroadcastReminderState
    let layoutStyle: DetailNavigationToolbarLayoutStyle

    static let standardExpanded = Self(
        broadcastReminderState: .hidden,
        layoutStyle: .expanded
    )
}

struct DetailNavigationToolbar<ReviewDestination: View>: ToolbarContent {
    let isFavorite: Bool
    let favoriteActionState: DetailNavigationToolbarPersistenceActionState
    let broadcastReminderActionState: DetailNavigationToolbarPersistenceActionState
    let configuration: DetailNavigationToolbarConfiguration
    let shareState: DetailNavigationToolbarShareState
    let reviewState: DetailNavigationToolbarReviewState
    let isRefreshing: Bool
    let onFavoriteTap: () -> Void
    let onBroadcastReminderTap: () -> Void
    let onRefreshTap: () -> Void
    let reviewDestination: (String) -> ReviewDestination

    init(
        isFavorite: Bool,
        favoriteActionState: DetailNavigationToolbarPersistenceActionState,
        broadcastReminderActionState: DetailNavigationToolbarPersistenceActionState = .available,
        configuration: DetailNavigationToolbarConfiguration = .standardExpanded,
        shareState: DetailNavigationToolbarShareState,
        reviewState: DetailNavigationToolbarReviewState,
        isRefreshing: Bool,
        onFavoriteTap: @escaping () -> Void,
        onBroadcastReminderTap: @escaping () -> Void = {},
        onRefreshTap: @escaping () -> Void,
        @ViewBuilder reviewDestination: @escaping (String) -> ReviewDestination
    ) {
        self.isFavorite = isFavorite
        self.favoriteActionState = favoriteActionState
        self.broadcastReminderActionState = broadcastReminderActionState
        self.configuration = configuration
        self.shareState = shareState
        self.reviewState = reviewState
        self.isRefreshing = isRefreshing
        self.onFavoriteTap = onFavoriteTap
        self.onBroadcastReminderTap = onBroadcastReminderTap
        self.onRefreshTap = onRefreshTap
        self.reviewDestination = reviewDestination
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            favoriteButton
        }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItemGroup(placement: .topBarTrailing) {
            broadcastReminderButton
            if configuration.layoutStyle == .compact {
                moreActionsMenu
            } else {
                shareAction
                reviewAction
                refreshButton
            }
        }
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteTap) {
            DetailNavigationToolbarIcon(
                systemName: isFavorite ? "heart.fill" : "heart",
                tintColor: favoriteActionState.tintColor
            )
            .frame(minWidth: 44, minHeight: 44)
        }
        .disabled(!favoriteActionState.isEnabled)
    }

    @ViewBuilder
    private var broadcastReminderButton: some View {
        switch configuration.broadcastReminderState {
        case .hidden:
            EmptyView()
        case .off:
            Button(action: onBroadcastReminderTap) {
                DetailNavigationToolbarIcon(
                    systemName: "bell",
                    tintColor: broadcastReminderActionState.tintColor
                )
                .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!broadcastReminderActionState.isEnabled)
        case .on:
            Button(action: onBroadcastReminderTap) {
                DetailNavigationToolbarIcon(
                    systemName: "bell.fill",
                    tintColor: broadcastReminderActionState.tintColor
                )
                .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!broadcastReminderActionState.isEnabled)
        }
    }

    private var moreActionsMenu: some View {
        Menu {
            shareMenuContent
            reviewMenuContent
            refreshMenuContent
        } label: {
            DetailNavigationToolbarIcon(
                systemName: "ellipsis",
                tintColor: ThemeColor.sakura
            )
            .frame(minWidth: 44, minHeight: 44)
        }
    }

    @ViewBuilder
    private var shareMenuContent: some View {
        switch shareState {
        case .loading:
            Button {} label: {
                Label("分享", systemImage: "square.and.arrow.up")
            }
            .disabled(true)
        case let .available(title, message, url):
            ShareLink(
                item: url,
                subject: Text(title),
                message: Text(message)
            ) {
                Label("分享", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var reviewMenuContent: some View {
        switch reviewState {
        case .loading:
            Button {} label: {
                Label("評論", systemImage: "text.bubble.fill")
            }
            .disabled(true)
        case let .available(title):
            NavigationLink {
                reviewDestination(title)
            } label: {
                Label("評論", systemImage: "text.bubble.fill")
            }
        }
    }

    private var refreshMenuContent: some View {
        Button(action: onRefreshTap) {
            Label("重新整理", systemImage: "arrow.trianglehead.counterclockwise")
        }
        .disabled(isRefreshing)
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
