//
//  GenreMangaListContainerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreMangaListContainerView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: GenreMangaViewModel
    let favoriteIDs: Set<Int>

    @State private var selectedGenre: MangaListGenreDTO?

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                GenreMangaListSkeletonView()

            case .error(let failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "漫畫分類暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    viewModel.loadSections()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            case .empty:
                FeatureEmptyStateCardView(
                    emptyState: .emptyCollection(
                        title: "目前沒有分類資料",
                        message: "稍後再回來看看，或重新整理頁面。"
                    ),
                    minHeight: 180
                )
                .padding(.vertical, 8)

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
                            GenreMangaSectionView(
                                section: section,
                                favoriteIDs: favoriteIDs,
                                onOpenCategoryDetail: {
                                    selectedGenre = section.genre
                                }
                            )
                        } header: {
                            GenreMangaSectionHeaderView(section: section)
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
            MangaCategoryDetailView(genre: genre)
        }
    }
}
