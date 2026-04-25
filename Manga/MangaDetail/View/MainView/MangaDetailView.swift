//
//  MangaDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import OSLog
import SwiftUI
import SwiftData

struct MangaDetailView: View {

    // MARK: - Properties

    let malId: Int

    @StateObject private var viewModel: MangaDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [MyListCollectionItem]

    // MARK: - Initialization

    init(malId: Int, service: MangaDetailServicing = MangaDetailService()) {
        let mediaKindRawValue = MyListMediaKind.manga.rawValue
        self.malId = malId
        _viewModel = StateObject(wrappedValue: MangaDetailViewModel(malId: malId, service: service))
        _favorites = Query(
            filter: #Predicate<MyListCollectionItem> {
                $0.malId == malId && $0.mediaKindRawValue == mediaKindRawValue
            }
        )
    }

    // MARK: - Nested Types

    enum Section: Identifiable {
        case header
        case highlights
        case score
        case synopsis
        case publication

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .score: return "score"
            case .synopsis: return "synopsis"
            case .publication: return "publication"
            }
        }
    }

    // MARK: - Sections

    private func sections(for manga: MangaDetailDTO) -> [Section] {
        var result: [Section] = [
            .header,
            .highlights,
            .score
        ]
        if viewModel.hasSynopsis(for: manga) {
            result.append(.synopsis)
        }
        if viewModel.hasPublicationInfo(for: manga) || viewModel.hasThemes(for: manga)
            || !viewModel.hasSynopsis(for: manga) {
            result.append(.publication)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, viewModel: MangaDetailViewModel, manga: MangaDetailDTO) -> some View {
        switch section {
        case .header:
            MangaDetailHeaderSectionView(viewModel: viewModel, manga: manga)
        case .highlights:
            MangaDetailHighlightsSectionView(viewModel: viewModel, manga: manga)
        case .score:
            MangaDetailScoreSectionView(viewModel: viewModel, manga: manga)
        case .synopsis:
            MangaDetailSynopsisSectionView(viewModel: viewModel, manga: manga)
        case .publication:
            MangaDetailPublicationSectionView(viewModel: viewModel, manga: manga)
        }
    }

    private var isFavorite: Bool {
        !favorites.isEmpty
    }

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            if let existing = favorites.first {
                modelContext.delete(existing)
            } else if let manga = viewModel.detail {
                let item = MyListCollectionItem(
                    malId: manga.malId,
                    mediaKind: .manga,
                    title: viewModel.displayTitle(for: manga),
                    subtitle: manga.titleEnglish ?? manga.title,
                    imageURLString: viewModel.posterURL(for: manga)?.absoluteString,
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
            AppLogger.persistence.error("Manga favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let manga = viewModel.detail {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: manga)) { section in
                            sectionView(section, viewModel: viewModel, manga: manga)
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
                        MangaDetailHeaderSectionSkeletonView()
                        MangaDetailHighlightsSectionSkeletonView()
                        MangaDetailScoreSectionSkeletonView()
                        MangaDetailSynopsisSectionSkeletonView()
                        MangaDetailPublicationSectionSkeletonView()
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
                .accessibilityLabel(isFavorite ? "移除漫畫收藏" : "加入漫畫收藏")

                NavigationLink {
                    MangaReviewView(
                        malId: malId,
                        mangaTitle: viewModel.detail.map { viewModel.displayTitle(for: $0) }
                    )
                } label: {
                    Image(systemName: "text.bubble.fill")
                        .font(.body.weight(.bold))
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
        MangaDetailView(malId: 1)
    }
}
