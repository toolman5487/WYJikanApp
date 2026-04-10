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

    // MARK: - View

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.genreSections.isEmpty {
                GenreAnimeListSkeletonView()
            } else if let message = viewModel.errorMessage, viewModel.genreSections.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            } else {
                ForEach(viewModel.genreSections) { section in
                    GenreAnimeSectionView(section: section)
                }

                if viewModel.canLoadMore {
                    Button {
                        viewModel.loadMoreSections()
                    } label: {
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 44)
                        } else {
                            Text("載入更多種類")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
                    .disabled(viewModel.isLoadingMore)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
