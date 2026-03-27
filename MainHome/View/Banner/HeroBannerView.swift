//
//  HeroBannerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct HeroBannerView: View {
    @StateObject private var viewModel = HeroBannerViewModel()
    @EnvironmentObject private var router: MainHomeRouter
    
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
                    Button {
                        router.push(.animeDetail(malId: item.id))
                    } label: {
                        HeroBannerSlideView(imageURL: item.imageURL)
                    }
                    .buttonStyle(.plain)
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

#Preview {
    HeroBannerView()
        .environmentObject(MainHomeRouter())
}
