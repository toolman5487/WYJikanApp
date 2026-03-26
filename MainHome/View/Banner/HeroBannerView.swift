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
            ErrorMessageView(message: "Empty Data", height: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let selectionBinding = Binding<Int>(
                get: { viewModel.currentIndex },
                set: { newValue in
                    viewModel.setCurrentIndex(newValue)
                }
            )

            TabView(selection: selectionBinding) {
                ForEach(viewModel.items.indices, id: \.self) { index in
                    let item = viewModel.items[index]

                    ZStack(alignment: .bottomLeading) {
                        HeroBannerImageView(url: item.imageURL)
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
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
}

#Preview {
    HeroBannerView()
}
