//
//  HeroBannerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct HeroBannerView: View {
    @StateObject private var viewModel = HeroBannerViewModel()

    private static let posterAspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.posterAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.stopAutoScroll()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            BannerSkeletonView()
        } else if let errorMessage = viewModel.errorMessage {
            ErrorMessageView(message: errorMessage, height: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.items.isEmpty {
            ErrorMessageView(message: viewModel.emptyStateMessage, height: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            TabView(selection: selectionBinding) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    HeroBannerSlideView(imageURL: item.imageURL)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentIndex },
            set: { viewModel.setCurrentIndex($0) }
        )
    }
}

// MARK: - Slide

private struct HeroBannerSlideView: View {
    let imageURL: URL

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroBannerImageView(url: imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.65)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HeroBannerView()
}
