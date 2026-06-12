//
//  AnimeDetailPicturesSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation
import SwiftUI

struct AnimeDetailPicturesSectionView: View {

    let viewModel: AnimeDetailViewModel
    let onTapImage: ((Int) -> Void)?

    init(viewModel: AnimeDetailViewModel, onTapImage: ((Int) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onTapImage = onTapImage
    }

    var body: some View {
        if viewModel.canShowFullPictureList {
            AnimeDetailLinkedSection(
                title: "劇照",
                actionTitle: "查看全部"
            ) {
                AnimeDetailPicturesListView(
                    viewModel: viewModel,
                    onTapImage: onTapImage
                )
            } content: {
                pictureGrid(items: viewModel.previewPictureItems)
            }
        } else {
            AnimeDetailSectionCard("劇照") {
                pictureGrid(items: viewModel.pictureItems)
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    @ViewBuilder
    private func pictureGrid(items: [AnimeDetailPictureItem]) -> some View {
        LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                DetailPictureGridItemView(url: item.url) {
                    onTapImage?(index)
                }
            }
        }
    }
}

struct AnimeDetailPicturesListView: View {
    let viewModel: AnimeDetailViewModel
    let onTapImage: ((Int) -> Void)?

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                    DetailPictureGridItemView(url: item.url) {
                        onTapImage?(index)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("劇照")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailPictureGridItemView: View {

    private static let aspectRatio: CGFloat = 2.0 / 3.0
    private static let cornerRadius: CGFloat = 12

    let url: URL
    let onTap: () -> Void

    var body: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    RemotePosterImageView(
                        url: url,
                        contentMode: .fill,
                        fixedSize: proxy.size
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    AnimeDetailPicturesSectionView(viewModel: AppDependencies.live.makeAnimeDetailViewModel(malId: 1))
        .padding()
}
