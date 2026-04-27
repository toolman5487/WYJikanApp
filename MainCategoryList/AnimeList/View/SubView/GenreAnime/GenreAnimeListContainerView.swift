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
            switch viewModel.screenState {
            case .loading:
                GenreAnimeListSkeletonView()
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
                if let message = inlineError {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                ForEach(sections) { section in
                    GenreAnimeSectionView(section: section)
                }

                switch loadMoreState {
                case .hidden:
                    EmptyView()
                case .available, .loading:
                    Button {
                        viewModel.loadMoreSections()
                    } label: {
                        if loadMoreState == .loading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 44)
                        } else {
                            Text("載入更多種類")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColor.sakura)
                    .disabled(loadMoreState == .loading)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
