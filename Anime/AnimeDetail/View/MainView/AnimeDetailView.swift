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
    @EnvironmentObject private var appPersistenceStore: AppPersistenceStore
    @State private var imagePreviewSession: ImagePreviewSession?
    @State private var isShowingCharacterList = false
    @State private var isShowingRecommendationList = false
    @State private var broadcastReminderAlertMessage: String?
    @State private var persistenceAlertMessage: String?
    @State private var watchProgressEditorDraft: AnimeWatchProgressEditorDraft?

    // MARK: - Lifecycle

    init(malId: Int, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: dependencies.makeAnimeDetailViewModel(malId: malId))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .refreshing(anime):
                detailScroll {
                    ForEach(viewModel.sections(for: anime)) { section in
                        sectionView(section, viewModel: viewModel, anime: anime)
                    }
                }
            case let .loaded(anime):
                detailScroll {
                    ForEach(viewModel.sections(for: anime)) { section in
                        sectionView(section, viewModel: viewModel, anime: anime)
                    }
                }
            case let .error(failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "作品資料暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    Task(priority: .userInitiated) { await viewModel.load(forceRefresh: true) }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .idle:
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
            case .loading:
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
                favoriteActionState: favoriteActionState,
                broadcastReminderActionState: persistenceActionState,
                configuration: navigationToolbarConfiguration,
                shareState: viewModel.shareNavigationState(),
                reviewState: viewModel.reviewNavigationState(),
                isRefreshing: viewModel.isRefreshing,
                onFavoriteTap: {
                    handleFavoriteTap()
                },
                onBroadcastReminderTap: {
                    handleBroadcastReminderTap()
                },
                onRefreshTap: {
                    Task(priority: .userInitiated) {
                        await viewModel.load(forceRefresh: true)
                        await syncBroadcastReminderIfAvailable()
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
        .alert(
            "收藏與提醒",
            isPresented: Binding(
                get: { persistenceAlertText != nil },
                set: { isPresented in
                    if !isPresented {
                        persistenceAlertMessage = nil
                        viewModel.dismissPersistenceMutationFailure()
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {
                persistenceAlertMessage = nil
                viewModel.dismissPersistenceMutationFailure()
            }
        } message: {
            Text(persistenceAlertText ?? "")
        }
        .fullScreenCover(item: $imagePreviewSession) { session in
            ImagePreviewViewer(
                items: session.items,
                selectedIndex: imagePreviewSelectedIndexBinding(for: session)
            )
        }
        .sheet(item: $watchProgressEditorDraft) { draft in
            AnimeWatchProgressEditorView(draft: draft) { updatedDraft in
                guard let favoriteItem = viewModel.favoriteCollectionItem else { return }
                viewModel.updateWatchProgress(
                    for: favoriteItem,
                    status: updatedDraft.status,
                    currentEpisode: updatedDraft.currentEpisode,
                    totalEpisodes: updatedDraft.totalEpisodes
                )
            }
        }
        .task(id: malId, priority: .userInitiated) {
            await viewModel.screenDidAppear()
        }
        .onDisappear {
            viewModel.screenDidDisappear()
        }
        .task(id: broadcastReminderSyncTrigger, priority: .utility) {
            guard appPersistenceStore.isReady, currentAnime != nil else { return }
            await syncBroadcastReminderIfAvailable()
        }
    }

    // MARK: - Private Methods

    private var isFavorite: Bool {
        favoriteStatusStore.isFavorite(malId: malId, mediaKind: .anime)
    }

    private var favoriteActionState: DetailNavigationToolbarPersistenceActionState {
        guard viewModel.isFavoriteActionEnabled else { return .loading }
        return persistenceActionState
    }

    private var persistenceActionState: DetailNavigationToolbarPersistenceActionState {
        if viewModel.persistenceMutationState.isProcessing {
            return .loading
        }

        switch appPersistenceStore.state {
        case .initializing:
            return .loading
        case .ready:
            return .available
        case .failed:
            return .unavailable
        }
    }

    private var broadcastReminderSyncTrigger: String {
        "\(malId)-\(appPersistenceStore.isReady)-\(currentAnime != nil)"
    }

    private var persistenceAlertText: String? {
        persistenceAlertMessage ?? viewModel.persistenceMutationState.failureMessage
    }

    private var navigationToolbarConfiguration: DetailNavigationToolbarConfiguration {
        guard let anime = currentAnime else {
            return .standardExpanded
        }
        return broadcastReminderStatusStore.navigationToolbarConfiguration(for: anime)
    }

    private var currentAnime: AnimeDetailDTO? {
        switch viewModel.screenState {
        case let .loaded(anime):
            return anime
        case let .refreshing(anime):
            return anime
        case .idle:
            return nil
        case .loading:
            return nil
        case .error:
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
            VStack(alignment: .leading, spacing: 20) {
                AnimeDetailHeaderSectionView(
                    viewModel: viewModel,
                    anime: anime,
                    onTapPoster: {
                        showImagePreview(for: anime, selectedImageURL: viewModel.posterURL(for: anime))
                    }
                )
                if let favoriteItem = viewModel.favoriteCollectionItem {
                    AnimeWatchProgressSectionView(
                        item: favoriteItem,
                        anime: anime,
                        onIncrement: { item in
                            viewModel.incrementWatchProgress(for: item, anime: anime)
                        },
                        onDecrement: { item in
                            viewModel.decrementWatchProgress(for: item, anime: anime)
                        },
                        onEdit: { item in
                            watchProgressEditorDraft = viewModel.watchProgressEditorDraft(
                                for: item,
                                anime: anime
                            )
                        }
                    )
                    .disabled(viewModel.persistenceMutationState.isProcessing)
                }
            }
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
            DetailSupplementarySectionStateView(
                state: viewModel.charactersState,
                title: "角色與聲優",
                isEmpty: { _ in viewModel.allCharacterRoles.isEmpty },
                onRetry: {
                    Task(priority: .userInitiated) {
                        await viewModel.reloadCharacters()
                    }
                },
                loading: {
                    AnimeDetailCharactersSectionSkeletonView()
                },
                content: { _ in
                    AnimeDetailCharactersSectionView(
                        viewModel: viewModel,
                        animeTitle: viewModel.displayTitle(for: anime),
                        isShowingCharacterList: $isShowingCharacterList
                    )
                }
            )
        case .staff:
            AnimeDetailStaffSectionView(viewModel: viewModel, anime: anime)
        case .pictures:
            DetailSupplementarySectionStateView(
                state: viewModel.picturesState,
                title: "劇照",
                isEmpty: \.isEmpty,
                onRetry: {
                    Task(priority: .userInitiated) {
                        await viewModel.reloadPictures()
                    }
                },
                loading: {
                    AnimeDetailPicturesSectionSkeletonView()
                },
                content: { _ in
                    AnimeDetailPicturesSectionView(
                        viewModel: viewModel,
                        onTapImage: { index in
                            showImagePreview(for: anime, selectedPictureIndex: index)
                        }
                    )
                }
            )
        case .recommendations:
            DetailSupplementarySectionStateView(
                state: viewModel.recommendationsState,
                title: "你可能也喜歡",
                isEmpty: { _ in viewModel.allRecommendations.isEmpty },
                onRetry: {
                    Task(priority: .userInitiated) {
                        await viewModel.reloadRecommendations()
                    }
                },
                loading: {
                    AnimeDetailRecommendationsSectionSkeletonView()
                },
                content: { _ in
                    AnimeDetailRecommendationsSectionView(
                        viewModel: viewModel,
                        animeTitle: viewModel.displayTitle(for: anime),
                        isShowingRecommendationList: $isShowingRecommendationList
                    )
                }
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

    private func handleFavoriteTap() {
        guard canPerformPersistenceAction() else { return }
        viewModel.toggleFavorite(isFavorite: isFavorite)
    }

    private func handleBroadcastReminderTap() {
        guard canPerformPersistenceAction() else { return }

        Task(priority: .userInitiated) {
            await toggleBroadcastReminder()
        }
    }

    private func canPerformPersistenceAction() -> Bool {
        guard !viewModel.persistenceMutationState.isProcessing else { return false }

        switch appPersistenceStore.state {
        case .initializing:
            return false
        case .ready:
            return true
        case .failed(let failure):
            persistenceAlertMessage = failure.message
            return false
        }
    }

    private func syncBroadcastReminderIfAvailable() async {
        guard appPersistenceStore.isReady else { return }

        await viewModel.syncBroadcastReminderIfNeeded(
            isSubscribed: broadcastReminderStatusStore.isSubscribed(malId: malId),
            subscribedCount: broadcastReminderStatusStore.subscriptions.count,
            notificationScheduler: todayAnimeNotificationScheduler
        )
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
            .environmentObject(AppPersistenceStore())
    }
}
