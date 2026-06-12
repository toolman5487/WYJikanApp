//
//  AnimeDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailView: View {
    let malId: Int

    var body: some View {
        AnimeDetailConfiguredView(malId: malId)
    }
}

private struct AnimeDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int

    var body: some View {
        AnimeDetailBodyView(malId: malId, dependencies: dependencies)
    }
}

private struct AnimeDetailBodyView: View {

    // MARK: - Types

    private struct ImagePreviewSession: Identifiable {
        let id = UUID()
        let items: [ImagePreviewItem]
        var selectedIndex: Int
    }

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: AnimeDetailViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @EnvironmentObject private var broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    @EnvironmentObject private var todayAnimeNotificationScheduler: HomeTodayAnimeNotificationScheduler
    @State private var imagePreviewSession: ImagePreviewSession?
    @State private var isShowingCharacterList = false
    @State private var isShowingRecommendationList = false
    @State private var broadcastReminderAlertMessage: String?

    // MARK: - Lifecycle

    init(malId: Int, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: dependencies.makeAnimeDetailViewModel(malId: malId))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .refreshing(anime), let .loaded(anime):
                detailScroll {
                    ForEach(viewModel.sections(for: anime)) { section in
                        sectionView(section, viewModel: viewModel, anime: anime)
                    }
                }
            case let .error(failure):
                ErrorMessageView(state: .network(failure.message), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .idle, .loading:
                detailScroll {
                    AnimeDetailHeaderSectionSkeletonView()
                    AnimeDetailHighlightsSectionSkeletonView()
                    AnimeDetailBasicInfoSectionSkeletonView()
                    AnimeDetailEpisodesEntrySectionSkeletonView()
                    AnimeDetailScoreSectionSkeletonView()
                    AnimeDetailTrailerSectionSkeletonView()
                    AnimeDetailSynopsisSectionSkeletonView()
                    AnimeDetailCharactersSectionSkeletonView()
                    AnimeDetailStaffSectionSkeletonView()
                    AnimeDetailPicturesSectionSkeletonView()
                    AnimeDetailRecommendationsSectionSkeletonView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingCharacterList) {
            if let anime = currentAnime {
                AnimeDetailCharactersListView(
                    animeTitle: viewModel.displayTitle(for: anime),
                    roles: viewModel.allCharacterRoles,
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingRecommendationList) {
            if let anime = currentAnime {
                AnimeDetailRecommendationsListView(
                    animeTitle: viewModel.displayTitle(for: anime),
                    rows: viewModel.recommendationRows(for: .list)
                )
            }
        }
        .toolbar {
            DetailNavigationToolbar(
                isFavorite: isFavorite,
                isFavoriteActionEnabled: viewModel.isFavoriteActionEnabled,
                configuration: navigationToolbarConfiguration,
                shareState: viewModel.shareNavigationState(),
                reviewState: viewModel.reviewNavigationState(),
                isRefreshing: viewModel.isRefreshing,
                onFavoriteTap: {
                    viewModel.toggleFavorite(isFavorite: isFavorite)
                },
                onBroadcastReminderTap: {
                    Task {
                        await toggleBroadcastReminder()
                    }
                },
                onRefreshTap: {
                    Task {
                        await viewModel.load(forceRefresh: true)
                        await viewModel.syncBroadcastReminderIfNeeded(
                            isSubscribed: broadcastReminderStatusStore.isSubscribed(malId: malId),
                            subscribedCount: broadcastReminderStatusStore.subscriptions.count,
                            notificationScheduler: todayAnimeNotificationScheduler
                        )
                    }
                },
                reviewDestination: { title in
                    AnimeReviewView(
                        malId: malId,
                        animeTitle: title
                    )
                }
            )
        }
        .alert(
            "播出提醒",
            isPresented: Binding(
                get: { broadcastReminderAlertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        broadcastReminderAlertMessage = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {
                broadcastReminderAlertMessage = nil
            }
        } message: {
            Text(broadcastReminderAlertMessage ?? "")
        }
        .fullScreenCover(item: $imagePreviewSession) { session in
            ImagePreviewViewer(
                items: session.items,
                selectedIndex: imagePreviewSelectedIndexBinding(for: session)
            )
        }
        .task(id: malId) {
            await viewModel.load()
            await viewModel.syncBroadcastReminderIfNeeded(
                isSubscribed: broadcastReminderStatusStore.isSubscribed(malId: malId),
                subscribedCount: broadcastReminderStatusStore.subscriptions.count,
                notificationScheduler: todayAnimeNotificationScheduler
            )
        }
    }

    // MARK: - Private Methods

    private var isFavorite: Bool {
        favoriteStatusStore.isFavorite(malId: malId, mediaKind: .anime)
    }

    private var navigationToolbarConfiguration: DetailNavigationToolbarConfiguration {
        guard let anime = currentAnime else {
            return .standardExpanded
        }
        return broadcastReminderStatusStore.navigationToolbarConfiguration(for: anime)
    }

    private var currentAnime: AnimeDetailDTO? {
        switch viewModel.screenState {
        case let .loaded(anime), let .refreshing(anime):
            return anime
        case .idle, .loading, .error:
            return nil
        }
    }

    private func detailScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                content()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func imagePreviewSelectedIndexBinding(for session: ImagePreviewSession) -> Binding<Int> {
        Binding(
            get: { imagePreviewSession?.selectedIndex ?? session.selectedIndex },
            set: { imagePreviewSession?.selectedIndex = $0 }
        )
    }

    @ViewBuilder
    private func sectionView(
        _ section: AnimeDetailViewModel.Section,
        viewModel: AnimeDetailViewModel,
        anime: AnimeDetailDTO
    ) -> some View {
        switch section {
        case .header:
            AnimeDetailHeaderSectionView(
                viewModel: viewModel,
                anime: anime,
                onTapPoster: {
                    showImagePreview(for: anime, selectedImageURL: viewModel.posterURL(for: anime))
                }
            )
        case .highlights:
            AnimeDetailHighlightsSectionView(viewModel: viewModel, anime: anime)
        case .basicInfo:
            AnimeDetailBasicInfoSectionView(viewModel: viewModel, anime: anime)
        case .episodes:
            AnimeDetailEpisodesEntrySectionView(
                viewModel: viewModel,
                anime: anime
            )
        case .score:
            AnimeDetailScoreSectionView(viewModel: viewModel, anime: anime)
        case .trailer:
            AnimeDetailTrailerSectionView(viewModel: viewModel, anime: anime)
        case .synopsis:
            AnimeDetailSynopsisSectionView(viewModel: viewModel, anime: anime)
        case .characters:
            AnimeDetailCharactersSectionView(
                viewModel: viewModel,
                animeTitle: viewModel.displayTitle(for: anime),
                isShowingCharacterList: $isShowingCharacterList
            )
        case .staff:
            AnimeDetailStaffSectionView(viewModel: viewModel, anime: anime)
        case .pictures:
            AnimeDetailPicturesSectionView(
                viewModel: viewModel,
                onTapImage: { index in
                    showImagePreview(for: anime, selectedPictureIndex: index)
                }
            )
        case .recommendations:
            AnimeDetailRecommendationsSectionView(
                viewModel: viewModel,
                animeTitle: viewModel.displayTitle(for: anime),
                isShowingRecommendationList: $isShowingRecommendationList
            )
        }
    }

    private func showImagePreview(for anime: AnimeDetailDTO, selectedImageURL: URL?) {
        let items = viewModel.imagePreviewItems(for: anime)
        guard !items.isEmpty else { return }
        let selectedIndex = viewModel.initialPreviewIndex(for: items, selectedImageURL: selectedImageURL)
        imagePreviewSession = ImagePreviewSession(items: items, selectedIndex: selectedIndex)
    }

    private func toggleBroadcastReminder() async {
        if let error = await viewModel.toggleBroadcastReminder(
            isSubscribed: broadcastReminderStatusStore.isSubscribed(malId: malId),
            subscribedCount: broadcastReminderStatusStore.subscriptions.count,
            notificationScheduler: todayAnimeNotificationScheduler
        ) {
            broadcastReminderAlertMessage = error.localizedDescription
        }
    }

    private func showImagePreview(for anime: AnimeDetailDTO, selectedPictureIndex: Int) {
        let items = viewModel.imagePreviewItems(for: anime)
        guard !items.isEmpty else { return }
        let selectedIndex = viewModel.initialPreviewIndex(
            for: anime,
            items: items,
            selectedPictureIndex: selectedPictureIndex
        )
        imagePreviewSession = ImagePreviewSession(items: items, selectedIndex: selectedIndex)
    }
}

#Preview {
    NavigationStack {
        AnimeDetailView(malId: 52991)
            .environmentObject(FavoriteStatusStore())
            .environmentObject(AnimeBroadcastReminderStatusStore())
            .environmentObject(HomeTodayAnimeNotificationScheduler())
    }
}
