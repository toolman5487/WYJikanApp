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
    
    @ViewBuilder
    private func sectionView(_ section: MangaDetailViewModel.Section, viewModel: MangaDetailViewModel, manga: MangaDetailDTO) -> some View {
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
                let item = viewModel.favoriteItem(for: manga)
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
            switch viewModel.screenState {
            case let .loaded(manga):
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
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
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
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItemGroup(placement: .topBarTrailing) {
                switch viewModel.reviewNavigationState() {
                case .loading:
                    Image(systemName: "text.bubble.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                case let .available(title):
                    NavigationLink {
                        MangaReviewView(
                            malId: malId,
                            mangaTitle: title
                        )
                    } label: {
                        Image(systemName: "text.bubble.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(ThemeColor.sakura)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
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
