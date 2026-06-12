//
//  MangaDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI
import SwiftData

struct MangaDetailView: View {
    let malId: Int

    var body: some View {
        MangaDetailConfiguredView(malId: malId)
    }
}

private struct MangaDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int

    var body: some View {
        MangaDetailBodyView(malId: malId, dependencies: dependencies)
    }
}

private struct MangaDetailBodyView: View {
    private struct ImagePreviewSession: Identifiable {
        let id = UUID()
        let items: [ImagePreviewItem]
        var selectedIndex: Int
    }

    // MARK: - Properties

    let malId: Int

    @StateObject private var viewModel: MangaDetailViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @Query(sort: \MyListCollectionItem.addedAt, order: .reverse)
    private var collectionItems: [MyListCollectionItem]
    @State private var imagePreviewSession: ImagePreviewSession?
    @State private var progressEditorDraft: MangaReadingProgressEditorDraft?
    @State private var isShowingCharacterList = false
    @State private var isShowingRecommendationList = false

    // MARK: - Initialization

    init(malId: Int, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: dependencies.makeMangaDetailViewModel(malId: malId))
    }

    @ViewBuilder
    private func sectionView(_ section: MangaDetailViewModel.Section, viewModel: MangaDetailViewModel, manga: MangaDetailDTO) -> some View {
        switch section {
        case .header:
            VStack(alignment: .leading, spacing: 20) {
                MangaDetailHeaderSectionView(
                    viewModel: viewModel,
                    manga: manga,
                    onTapPoster: {
                        showImagePreview(for: manga, selectedImageURL: viewModel.posterURL(for: manga))
                    }
                )
                if let favoriteItem {
                    MangaReadingProgressSectionView(
                        item: favoriteItem,
                        manga: manga,
                        onIncrement: { item in
                            viewModel.incrementReadingProgress(for: item, manga: manga)
                        },
                        onDecrement: { item in
                            viewModel.decrementReadingProgress(for: item, manga: manga)
                        },
                        onEdit: { item in
                            progressEditorDraft = viewModel.readingProgressEditorDraft(
                                for: item,
                                manga: manga
                            )
                        }
                    )
                }
            }
        case .highlights:
            MangaDetailHighlightsSectionView(viewModel: viewModel, manga: manga)
        case .basicInfo:
            MangaDetailBasicInfoSectionView(viewModel: viewModel, manga: manga)
        case .score:
            MangaDetailScoreSectionView(viewModel: viewModel, manga: manga)
        case .synopsis:
            MangaDetailSynopsisSectionView(viewModel: viewModel, manga: manga)
        case .characters:
            MangaDetailCharactersSectionView(
                viewModel: viewModel,
                mangaTitle: viewModel.displayTitle(for: manga),
                isShowingCharacterList: $isShowingCharacterList
            )
        case .publication:
            MangaDetailPublicationSectionView(viewModel: viewModel, manga: manga)
        case .pictures:
            MangaDetailPicturesSectionView(
                viewModel: viewModel,
                onTapImage: { index in
                    showImagePreview(for: manga, selectedPictureIndex: index)
                }
            )
        case .recommendations:
            MangaDetailRecommendationsSectionView(
                viewModel: viewModel,
                mangaTitle: viewModel.displayTitle(for: manga),
                isShowingRecommendationList: $isShowingRecommendationList
            )
        }
    }

    private func showImagePreview(for manga: MangaDetailDTO, selectedImageURL: URL?) {
        let items = viewModel.imagePreviewItems(for: manga)
        guard !items.isEmpty else { return }
        let selectedIndex = viewModel.initialPreviewIndex(for: items, selectedImageURL: selectedImageURL)
        imagePreviewSession = ImagePreviewSession(items: items, selectedIndex: selectedIndex)
    }

    private func showImagePreview(for manga: MangaDetailDTO, selectedPictureIndex: Int) {
        let items = viewModel.imagePreviewItems(for: manga)
        guard !items.isEmpty else { return }
        let selectedIndex = viewModel.initialPreviewIndex(
            for: manga,
            items: items,
            selectedPictureIndex: selectedPictureIndex
        )
        imagePreviewSession = ImagePreviewSession(items: items, selectedIndex: selectedIndex)
    }

    private var isFavorite: Bool {
        favoriteStatusStore.isFavorite(malId: malId, mediaKind: .manga)
    }

    private var favoriteItem: MyListCollectionItem? {
        collectionItems.first { item in
            item.malId == malId && item.mediaKind == .manga
        }
    }

    private var currentManga: MangaDetailDTO? {
        switch viewModel.screenState {
        case let .loaded(manga), let .refreshing(manga):
            return manga
        case .idle, .loading, .error:
            return nil
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .refreshing(manga), let .loaded(manga):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.sections(for: manga)) { section in
                            sectionView(section, viewModel: viewModel, manga: manga)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case let .error(message):
                ErrorMessageView(state: .network(message), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .idle, .loading:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        MangaDetailHeaderSectionSkeletonView()
                        MangaDetailHighlightsSectionSkeletonView()
                        AnimeDetailBasicInfoSectionSkeletonView()
                        MangaDetailScoreSectionSkeletonView()
                        MangaDetailSynopsisSectionSkeletonView()
                        MangaDetailCharactersSectionSkeletonView()
                        MangaDetailPublicationSectionSkeletonView()
                        AnimeDetailPicturesSectionSkeletonView()
                        MangaDetailRecommendationsSectionSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingCharacterList) {
            if let manga = currentManga {
                MangaDetailCharactersListView(
                    mangaTitle: viewModel.displayTitle(for: manga),
                    roles: viewModel.allCharacterRoles,
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingRecommendationList) {
            if let manga = currentManga {
                MangaDetailRecommendationsListView(
                    mangaTitle: viewModel.displayTitle(for: manga),
                    rows: viewModel.recommendationRows(for: .list)
                )
            }
        }
        .toolbar {
            DetailNavigationToolbar(
                isFavorite: isFavorite,
                isFavoriteActionEnabled: viewModel.isFavoriteActionEnabled,
                shareState: viewModel.shareNavigationState(),
                reviewState: viewModel.reviewNavigationState(),
                isRefreshing: viewModel.isRefreshing,
                onFavoriteTap: {
                    viewModel.toggleFavorite(isFavorite: isFavorite)
                },
                onRefreshTap: {
                    Task {
                        await viewModel.load(forceRefresh: true)
                    }
                },
                reviewDestination: { title in
                    MangaReviewView(
                        malId: malId,
                        mangaTitle: title
                    )
                }
            )
        }
        .fullScreenCover(item: $imagePreviewSession) { session in
            ImagePreviewViewer(
                items: session.items,
                selectedIndex: Binding(
                    get: { imagePreviewSession?.selectedIndex ?? session.selectedIndex },
                    set: { newValue in
                        imagePreviewSession?.selectedIndex = newValue
                    }
                )
            )
        }
        .sheet(item: $progressEditorDraft) { draft in
            MangaReadingProgressEditorView(draft: draft) { updatedDraft in
                guard let favoriteItem else { return }
                viewModel.updateReadingProgress(
                    for: favoriteItem,
                    status: updatedDraft.status,
                    currentChapter: updatedDraft.currentChapter,
                    totalChapters: updatedDraft.totalChapters
                )
            }
        }
        .task(id: malId) {
            await viewModel.load()
        }
    }
}

#Preview {
    NavigationStack {
        MangaDetailView(malId: 1)
            .environmentObject(FavoriteStatusStore())
    }
}
