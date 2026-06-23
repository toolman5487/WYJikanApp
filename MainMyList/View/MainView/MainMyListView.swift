//
//  MainMyListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MainMyListView: View {
    // MARK: - Types

    private enum ContentState {
        case empty
        case populated
    }

    private enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let toolbarButtonSize: CGFloat = 44
    }

    // MARK: - Properties

    @EnvironmentObject private var broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @EnvironmentObject private var notificationScheduler: HomeTodayAnimeNotificationScheduler
    @EnvironmentObject private var appPersistenceStore: AppPersistenceStore

    private let dependencies: MyListDependencies

    @StateObject private var viewModel: MainMyListViewModel
    @StateObject private var randomAnimeViewModel: RandomHeroViewModel
    @StateObject private var randomMangaViewModel: RandomMangaViewModel

    @State private var genreCollectionsRoute: MyListGenreCollectionsRoute?
    @State private var formatCollectionsRoute: MyListFormatCollectionsRoute?
    @State private var isShowingAnimeWatchStatusQuery = false
    @State private var isShowingMangaReadingStatusQuery = false
    @State private var isShowingSettings = false

    // MARK: - Lifecycle

    init(dependencies: MyListDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeMainViewModel())
        _randomAnimeViewModel = StateObject(wrappedValue: dependencies.makeRandomAnimeViewModel())
        _randomMangaViewModel = StateObject(wrappedValue: dependencies.makeRandomMangaViewModel())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch appPersistenceStore.state {
                case .initializing:
                    loadingView
                case .ready:
                    loadedView
                case .failed(let failure):
                    persistenceFailureView(failure)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if appPersistenceStore.isReady {
                    ToolbarItem(placement: .topBarTrailing) {
                        settingsButton
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingView(
                    dependencies: dependencies,
                    notificationScheduler: notificationScheduler,
                    broadcastReminderStatusStore: broadcastReminderStatusStore,
                    favoriteStatusStore: favoriteStatusStore
                )
            }
            .navigationDestination(item: $genreCollectionsRoute) { route in
                MyListGenreCollectionsDetailView(route: route)
            }
            .navigationDestination(item: $formatCollectionsRoute) { route in
                MyListFormatCollectionsDetailView(route: route)
            }
            .navigationDestination(isPresented: $isShowingAnimeWatchStatusQuery) {
                AnimeWatchStatusQueryView(dependencies: dependencies)
            }
            .navigationDestination(isPresented: $isShowingMangaReadingStatusQuery) {
                MangaReadingStatusQueryView(dependencies: dependencies)
            }
            .alert(
                "收藏功能",
                isPresented: Binding(
                    get: { viewModel.persistenceMutationState.failureMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.dismissPersistenceMutationFailure()
                        }
                    }
                )
            ) {
                Button("好", role: .cancel) {
                    viewModel.dismissPersistenceMutationFailure()
                }
            } message: {
                Text(viewModel.persistenceMutationState.failureMessage ?? "")
            }
            .onDisappear {
                randomAnimeViewModel.stop()
                randomMangaViewModel.stop()
            }
        }
    }

    // MARK: - Private Views

    private var loadedView: some View {
        let presentation = viewModel.presentation

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                headerView
                filterView
                randomPickSectionView
                summaryView(presentation: presentation)
                progressStatusSectionView(presentation: presentation)
                contentView(presentation: presentation)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
        .task(id: viewModel.selectedFilter, priority: .userInitiated) {
            loadRandomPickIfNeeded(for: viewModel.selectedFilter)
        }
    }

    private var loadingView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SkeletonBar(width: 224, height: 16, cornerRadius: 8)
                MyListCategorySkeletonView()
                MyListSummarySkeletonView()
                MyListFavoritesSkeletonView()
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
    }

    private func persistenceFailureView(_ failure: FeatureLoadFailure) -> some View {
        ScrollView {
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                title: "收藏資料暫時無法使用",
                retryTitle: "重新連線",
                onRetry: appPersistenceStore.retryInitialization
            )
            .padding(Layout.horizontalPadding)
        }
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.body.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)
                .frame(width: Layout.toolbarButtonSize, height: Layout.toolbarButtonSize)
        }
        .buttonStyle(.plain)
    }

    private var headerView: some View {
        Text("把想追的動畫與漫畫集中在這裡。")
            .font(.subheadline)
            .foregroundStyle(ThemeColor.textSecondary)
    }

    private var filterView: some View {
        CapsuleFilterBarView(
            tags: MyListFilter.allCases,
            title: { $0.title },
            selection: $viewModel.selectedFilter,
            selectionAnimation: nil
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .zIndex(1)
    }

    @ViewBuilder
    private var randomPickSectionView: some View {
        switch viewModel.selectedFilter {
        case .all:
            EmptyView()
        case .anime:
            RandomHeroSectionView(
                viewModel: randomAnimeViewModel,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .anime)
            )
        case .manga:
            RandomMangaSectionView(
                viewModel: randomMangaViewModel,
                favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga)
            )
        }
    }

    private func summaryView(presentation: MyListPresentation) -> some View {
        MyListStatisticsSectionView(
            presentation: presentation,
            onSelectGenre: { genreName in
                showGenreCollectionsDetail(
                    selectedGenreName: genreName,
                    presentation: presentation
                )
            },
            onSelectFormat: { formatTitle in
                showFormatCollectionsDetail(
                    selectedFormatTitle: formatTitle,
                    presentation: presentation
                )
            }
        )
    }

    @ViewBuilder
    private func progressStatusSectionView(presentation: MyListPresentation) -> some View {
        switch viewModel.selectedFilter {
        case .all:
            animeWatchStatusEntryView(
                title: "動畫觀看狀態",
                summary: presentation.animeWatchStatusSummary
            )
            mangaReadingStatusEntryView(
                title: "漫畫閱讀狀態",
                summary: presentation.mangaReadingStatusSummary
            )
        case .anime:
            animeWatchStatusEntryView(
                title: "觀看狀態",
                summary: presentation.animeWatchStatusSummary
            )
        case .manga:
            mangaReadingStatusEntryView(
                title: "閱讀狀態",
                summary: presentation.mangaReadingStatusSummary
            )
        }
    }

    @ViewBuilder
    private func animeWatchStatusEntryView(
        title: String,
        summary: AnimeWatchStatusSummary
    ) -> some View {
        if summary.totalCount > 0 {
            AnimeWatchStatusEntryView(
                title: title,
                summary: summary
            ) {
                isShowingAnimeWatchStatusQuery = true
            }
        }
    }

    @ViewBuilder
    private func mangaReadingStatusEntryView(
        title: String,
        summary: MangaReadingStatusSummary
    ) -> some View {
        if summary.totalCount > 0 {
            MangaReadingStatusEntryView(
                title: title,
                summary: summary
            ) {
                isShowingMangaReadingStatusQuery = true
            }
        }
    }

    @ViewBuilder
    private func contentView(presentation: MyListPresentation) -> some View {
        switch contentState(for: presentation) {
        case .empty:
            MyListEmptyStateView(emptyState: viewModel.emptyState())

        case .populated:
            LazyVStack(spacing: Layout.rowSpacing) {
                ForEach(presentation.filteredItems) { item in
                    NavigationLink {
                        destinationView(for: item)
                    } label: {
                        MyListItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(item)
                        } label: {
                            Label("移除收藏", systemImage: "heart.slash")
                        }
                        .disabled(viewModel.persistenceMutationState.isProcessing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for item: MyListItemSnapshot) -> some View {
        switch item.mediaKind {
        case .anime:
            AnimeDetailView(malId: item.malId)
        case .manga:
            MangaDetailView(malId: item.malId)
        }
    }

    // MARK: - Private Methods

    private func contentState(for presentation: MyListPresentation) -> ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
    }

    private func loadRandomPickIfNeeded(for filter: MyListFilter) {
        switch filter {
        case .all:
            break
        case .anime:
            randomAnimeViewModel.loadIfNeeded()
        case .manga:
            randomMangaViewModel.loadIfNeeded()
        }
    }

    private func showGenreCollectionsDetail(
        selectedGenreName: String,
        presentation: MyListPresentation
    ) {
        genreCollectionsRoute = MyListGenreCollectionsRoute(
            scopeTitle: presentation.statistics.selectedAnalysis.scope.title,
            genreSections: presentation.genreSections,
            selectedGenreName: selectedGenreName
        )
    }

    private func showFormatCollectionsDetail(
        selectedFormatTitle: String,
        presentation: MyListPresentation
    ) {
        formatCollectionsRoute = MyListFormatCollectionsRoute(
            scopeTitle: presentation.statistics.formatAnalysis.scope.title,
            formatSections: presentation.formatSections,
            selectedFormatTitle: selectedFormatTitle
        )
    }
}

#Preview {
    MainMyListView(dependencies: AppDependencies.live.myList)
        .environmentObject(AppPersistenceStore())
}
