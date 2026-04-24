//
//  AnimeDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailView: View {

    private struct ImagePreviewSession: Identifiable {
        let id = UUID()
        let items: [ImagePreviewItem]
        var selectedIndex: Int
    }
    
    let malId: Int
    @StateObject private var viewModel: AnimeDetailViewModel
    @State private var imagePreviewSession: ImagePreviewSession?
    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(malId: malId, service: service))
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AnimeReviewView(
                        malId: malId,
                        animeTitle: viewModel.detail.map { viewModel.displayTitle(for: $0) }
                    )
                } label: {
                    Image(systemName: "text.bubble.fill")
                        .font(.body)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
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
