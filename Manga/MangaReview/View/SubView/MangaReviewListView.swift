//
//  MangaReviewListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewListView: View {

    @ObservedObject var viewModel: MangaReviewViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(viewModel.reviews.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                    }
                    MangaReviewRowView(viewModel: viewModel, entry: entry)
                }

                switch viewModel.loadMoreState {
                case .hidden:
                    EmptyView()
                case .available, .loading:
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        HStack {
                            if case .loading = viewModel.loadMoreState {
                                ProgressView()
                            }
                            Text("載入更多")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(ThemeColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .background(ThemeColor.sakura)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled({
                        if case .loading = viewModel.loadMoreState {
                            return true
                        }
                        return false
                    }())
                case .error(let message):
                    VStack(spacing: 10) {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)

                        Button("重試載入更多") {
                            Task { await viewModel.loadMore() }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(ThemeColor.sakura)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
