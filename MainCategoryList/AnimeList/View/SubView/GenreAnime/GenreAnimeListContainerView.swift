//
//  GenreAnimeListContainerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreAnimeListContainerView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: GenreAnimeViewModel
    let favoriteIDs: Set<Int>

    @State private var selectedGenre: AnimeListGenreDTO?

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                GenreAnimeListSkeletonView()

            case .error(let failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "動畫分類暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    viewModel.loadSections()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            case .empty:
                ErrorMessageView(
                    state: .emptyCollection("目前沒有分類資料"),
                    height: 180
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

            case .content(let sections, let inlineError, let loadMoreState):
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if let failure = inlineError {
                        ErrorMessageView(state: ErrorMessageView.State(failure: failure))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }

                    ForEach(sections) { section in
                        Section {
                            GenreAnimeSectionView(
                                section: section,
                                favoriteIDs: favoriteIDs,
                                onOpenCategoryDetail: {
                                    selectedGenre = section.genre
                                }
                            )
                        } header: {
                            GenreAnimeSectionHeaderView(section: section)
                        }
                    }

                    switch loadMoreState {
                    case .hidden:
                        EmptyView()

                    case .available, .loading:
                        EmptyView()
                    }
                }
            }
        }
        .navigationDestination(item: $selectedGenre) { genre in
            AnimeCategoryDetailView(genre: genre)
        }
    }
}
