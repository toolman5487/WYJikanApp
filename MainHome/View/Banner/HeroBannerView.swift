//
//  HeroBannerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct HeroBannerView: View {
    @StateObject private var viewModel = HeroBannerViewModel()

    private let bannerHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: bannerHeight)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.large)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(height: bannerHeight)
            } else if viewModel.items.isEmpty {
                Text("沒有輪播資料")
                    .foregroundStyle(.secondary)
                    .frame(height: bannerHeight)
            } else {
                let selectionBinding = Binding<Int>(
                    get: { viewModel.currentIndex },
                    set: { newValue in
                        viewModel.setCurrentIndex(newValue)
                    }
                )

                TabView(selection: selectionBinding) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: item.imageURL) { phase in
                                switch phase {
                                case .empty:
                                    Color(.systemBackground)
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Color(.systemBackground)
                                        .overlay(Image(systemName: "photo").imageScale(.large))
                                @unknown default:
                                    Color(.systemBackground)
                                }
                            }
                            .clipped()

                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.black.opacity(0.65)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .frame(height: bannerHeight)

                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(12)
                                .lineLimit(2)
                        }
                        .frame(height: bannerHeight)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: bannerHeight)
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.stopAutoScroll()
        }
    }
}

#Preview {
    HeroBannerView()
}
