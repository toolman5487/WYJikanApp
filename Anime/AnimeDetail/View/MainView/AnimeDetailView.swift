//
//  AnimeDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import OSLog
import SwiftUI
import SwiftData

struct AnimeDetailView: View {

    private struct ImagePreviewSession: Identifiable {
        let id = UUID()
        let items: [ImagePreviewItem]
        var selectedIndex: Int
    }
    
    let malId: Int
    @StateObject private var viewModel: AnimeDetailViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @Environment(\.modelContext) private var modelContext
    @State private var imagePreviewSession: ImagePreviewSession?
    private let detailService: any AnimeDetailServicing
    private let favoriteRepository: any FavoriteRepository

    init(
        malId: Int,
        service: AnimeDetailServicing = AnimeDetailService(),
        favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared
    ) {
        self.malId = malId
        self.detailService = service
        self.favoriteRepository = favoriteRepository
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(malId: malId, service: service))
    }

    @ViewBuilder
    private func sectionView(_ section: AnimeDetailViewModel.Section, viewModel: AnimeDetailViewModel, anime: AnimeDetailDTO) -> some View {
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
                anime: anime,
                service: detailService
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
                animeTitle: viewModel.displayTitle(for: anime)
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
                animeTitle: viewModel.displayTitle(for: anime)
            )
        }
    }

    private func showImagePreview(for anime: AnimeDetailDTO, selectedImageURL: URL?) {
        let items = viewModel.imagePreviewItems(for: anime)
        guard !items.isEmpty else { return }
        let selectedIndex = viewModel.initialPreviewIndex(for: items, selectedImageURL: selectedImageURL)
        imagePreviewSession = ImagePreviewSession(items: items, selectedIndex: selectedIndex)
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

    private var isFavorite: Bool {
        favoriteStatusStore.isFavorite(malId: malId, mediaKind: .anime)
    }

    private func toggleFavorite() {
        do {
            if isFavorite {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    modelContext: modelContext,
                    makeItem: nil
                )
            } else if let anime = viewModel.detail {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    modelContext: modelContext,
                    makeItem: { viewModel.favoriteItem(for: anime) }
                )
            }
        } catch {
            AppLogger.persistence.error("Anime favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .refreshing(anime), let .loaded(anime):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.sections(for: anime)) { section in
                            sectionView(section, viewModel: viewModel, anime: anime)
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
                        AnimeDetailHeaderSectionSkeletonView()
                        AnimeDetailHighlightsSectionSkeletonView()
                        AnimeDetailBasicInfoSectionSkeletonView()
                        AnimeDetailScoreSectionSkeletonView()
                        AnimeDetailTrailerSectionSkeletonView()
                        AnimeDetailSynopsisSectionSkeletonView()
                        AnimeDetailStaffSectionSkeletonView()
                        AnimeDetailPicturesSectionSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(viewModel.detail == nil)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                switch viewModel.reviewNavigationState() {
                case .loading:
                    Image(systemName: "text.bubble.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.textSecondary)
                        .frame(width: 44, height: 44)
                case let .available(title):
                    NavigationLink {
                        AnimeReviewView(
                            malId: malId,
                            animeTitle: title
                        )
                    } label: {
                        Image(systemName: "text.bubble.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(ThemeColor.sakura)
                            .frame(width: 44, height: 44)
                    }
                }

                Button {
                    Task {
                        await viewModel.load(forceRefresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .symbolEffect(.rotate, options: .repeating, isActive: viewModel.isRefreshing)
                        .opacity(viewModel.isRefreshing ? 0.7 : 1)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
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
        AnimeDetailView(malId: 52991)
            .environmentObject(FavoriteStatusStore())
    }
}
