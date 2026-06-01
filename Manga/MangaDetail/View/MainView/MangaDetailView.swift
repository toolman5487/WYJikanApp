//
//  MangaDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI
import SwiftData

struct MangaDetailView: View {
    private struct ImagePreviewSession: Identifiable {
        let id = UUID()
        let items: [ImagePreviewItem]
        var selectedIndex: Int
    }
    
    // MARK: - Properties
    
    let malId: Int
    
    @StateObject private var viewModel: MangaDetailViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @Environment(\.modelContext) private var modelContext
    @State private var imagePreviewSession: ImagePreviewSession?
    
    // MARK: - Initialization
    
    init(
        malId: Int,
        service: MangaDetailServicing = MangaDetailService(),
        favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared
    ) {
        self.malId = malId
        _viewModel = StateObject(
            wrappedValue: MangaDetailViewModel(
                malId: malId,
                service: service,
                favoriteRepository: favoriteRepository
            )
        )
    }
    
    @ViewBuilder
    private func sectionView(_ section: MangaDetailViewModel.Section, viewModel: MangaDetailViewModel, manga: MangaDetailDTO) -> some View {
        switch section {
        case .header:
            MangaDetailHeaderSectionView(
                viewModel: viewModel,
                manga: manga,
                onTapPoster: {
                    showImagePreview(for: manga, selectedImageURL: viewModel.posterURL(for: manga))
                }
            )
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
                mangaTitle: viewModel.displayTitle(for: manga)
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
                mangaTitle: viewModel.displayTitle(for: manga)
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
                        MangaDetailPublicationSectionSkeletonView()
                        AnimeDetailPicturesSectionSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailNavigationToolbar(
                isFavorite: isFavorite,
                isFavoriteActionEnabled: viewModel.isFavoriteActionEnabled,
                shareState: viewModel.shareNavigationState(),
                reviewState: viewModel.reviewNavigationState(),
                isRefreshing: viewModel.isRefreshing,
                onFavoriteTap: {
                    viewModel.toggleFavorite(
                        isFavorite: isFavorite,
                        modelContext: modelContext
                    )
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
