//
//  AnimeReviewListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewListView: View {

    @ObservedObject var viewModel: AnimeReviewViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(viewModel.reviews.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                    }
                    AnimeReviewRowView(viewModel: viewModel, entry: entry)
                }

                if viewModel.hasNextPage {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        HStack {
                            if viewModel.isLoadingMore {
                                ProgressView()
                            }
                            Text("載入更多")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoadingMore)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
