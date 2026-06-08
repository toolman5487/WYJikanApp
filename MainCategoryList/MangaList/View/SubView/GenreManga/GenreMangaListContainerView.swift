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

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                GenreMangaListSkeletonView()
            case .error(let message):
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            case .empty:
                Text("目前沒有分類資料")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            case .content(let sections, let inlineError, let loadMoreState):
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if let message = inlineError {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    ForEach(sections) { section in
                        Section {
                            GenreMangaSectionView(
                                section: section,
                                favoriteIDs: favoriteIDs
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
    }
}
