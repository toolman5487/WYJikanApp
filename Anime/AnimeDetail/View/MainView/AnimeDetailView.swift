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
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [MyListCollectionItem]
    @State private var imagePreviewSession: ImagePreviewSession?
    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        let mediaKindRawValue = MyListMediaKind.anime.rawValue
        self.malId = malId
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(malId: malId, service: service))
        _favorites = Query(
            filter: #Predicate<MyListCollectionItem> {
                $0.malId == malId && $0.mediaKindRawValue == mediaKindRawValue
            }
        )
    }
    
    enum Section: Identifiable {
        case header
        case highlights
        case basicInfo
        case score
        case trailer
        case synopsis
        case staff
        case pictures

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .basicInfo: return "basicInfo"
            case .score: return "score"
            case .trailer: return "trailer"
            case .synopsis: return "synopsis"
            case .staff: return "staff"
            case .pictures: return "pictures"
            }
        }
    }
    
    // MARK: - Sections

    private func sections(for anime: AnimeDetailDTO) -> [Section] {
        var result: [Section] = [
            .header,
            .highlights,
            .basicInfo,
            .score
        ]
        if viewModel.hasTrailer(for: anime) {
            result.append(.trailer)
        }
        if viewModel.hasSynopsis(for: anime) {
            result.append(.synopsis)
        }
        if viewModel.hasStaffInfo(for: anime) || viewModel.hasThemes(for: anime) {
            result.append(.staff)
        }
        if viewModel.hasPictures {
            result.append(.pictures)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, viewModel: AnimeDetailViewModel, anime: AnimeDetailDTO) -> some View {
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
        case .score:
            AnimeDetailScoreSectionView(viewModel: viewModel, anime: anime)
        case .trailer:
            AnimeDetailTrailerSectionView(viewModel: viewModel, anime: anime)
        case .synopsis:
            AnimeDetailSynopsisSectionView(viewModel: viewModel, anime: anime)
        case .staff:
            AnimeDetailStaffSectionView(viewModel: viewModel, anime: anime)
        case .pictures:
            AnimeDetailPicturesSectionView(
                viewModel: viewModel,
                onTapImage: { index in
                    showImagePreview(for: anime, selectedPictureIndex: index)
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
        !favorites.isEmpty
    }

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            if let existing = favorites.first {
                modelContext.delete(existing)
            } else if let anime = viewModel.detail {
                let item = MyListCollectionItem(
                    malId: anime.malId,
                    mediaKind: .anime,
                    title: viewModel.displayTitle(for: anime),
                    subtitle: anime.titleEnglish ?? anime.title,
                    imageURLString: viewModel.posterURL(for: anime)?.absoluteString,
                    addedAt: Date()
                )
                modelContext.insert(item)
            } else {
                return
            }
        }

        do {
            try modelContext.save()
        } catch {
            AppLogger.persistence.error("Anime favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    var body: some View {
        Group {
            if let anime = viewModel.detail {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: anime)) { section in
                            sectionView(section, viewModel: viewModel, anime: anime)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let message = viewModel.errorMessage {
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                .accessibilityLabel(isFavorite ? "移除動畫收藏" : "加入動畫收藏")
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    AnimeReviewView(
                        malId: malId,
                        animeTitle: viewModel.detail.map { viewModel.displayTitle(for: $0) }
                    )
                } label: {
                    Image(systemName: "text.bubble.fill")
                        .font(.body.weight(.bold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Button {
                    Task {
                        await viewModel.load(forceRefresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .symbolEffect(.rotate, options: .repeating, isActive: viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.7 : 1)
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
    }
}
