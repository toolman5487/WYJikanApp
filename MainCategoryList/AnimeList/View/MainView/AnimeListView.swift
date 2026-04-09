//
//  AnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct AnimeListView: View {
    // MARK: - Properties

    @StateObject private var viewModel = AnimeListViewModel()

    // MARK: - View

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            RandomHeroSectionView(viewModel: viewModel.randomHeroViewModel)
            GenreAnimeListContainerView(viewModel: viewModel.genreAnimeViewModel)
        }
        .padding(.top, 8)
        .onDisappear {
            viewModel.stop()
        }
    }

}

#Preview {
    NavigationStack {
        ScrollView {
            AnimeListView()
                .padding(.horizontal)
        }
    }
}

private struct GenreAnimeListContainerView: View {
    private static let skeletonCount: Int = 6
    private static let skeletonCardHeight: CGFloat = 240
    private static let skeletonPosterAspectRatio: CGFloat = 2.0 / 3.0
    private static let skeletonCardCornerRadius: CGFloat = 16
    private static let skeletonCardSpacing: CGFloat = 12
    private static let skeletonHorizontalPadding: CGFloat = 16
    private static let skeletonSectionCount: Int = 3

    @ObservedObject var viewModel: GenreAnimeViewModel

    private var genreSkeletonSectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<Self.skeletonSectionCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBar(width: 120, height: 24, cornerRadius: 8)
                        .padding(.horizontal, Self.skeletonHorizontalPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Self.skeletonCardSpacing) {
                            ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                                RoundedRectangle(
                                    cornerRadius: Self.skeletonCardCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color(.systemGray5))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: Self.skeletonCardCornerRadius,
                                        style: .continuous
                                    )
                                )
                                .frame(
                                    width: Self.skeletonCardHeight * Self.skeletonPosterAspectRatio,
                                    height: Self.skeletonCardHeight
                                )
                            }
                        }
                        .padding(.horizontal, Self.skeletonHorizontalPadding)
                    }
                }
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.genreSections.isEmpty {
                genreSkeletonSectionView
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
