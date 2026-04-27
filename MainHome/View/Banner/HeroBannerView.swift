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
    
    private static let heroAspectRatio: CGFloat = 2.0 / 3.0
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.heroAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear {
            viewModel.loadIfNeeded()
            viewModel.resumeAutoScrollIfNeeded()
        }
        .onDisappear {
            viewModel.stopAutoScroll()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.screenState {
        case .loading:
            BannerSkeletonView()
        case .error(let errorMessage):
            bannerMessageView(message: errorMessage, buttonTitle: "重試")
        case .empty:
            bannerMessageView(message: viewModel.emptyStateMessage, buttonTitle: "重新整理")
        case .content:
            TabView(selection: selectionBinding) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        router.push(.animeDetail(malId: item.id))
                    } label: {
                        HeroBannerSlideView(item: item, pageLabel: "\(index + 1) / \(viewModel.items.count)")
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private func bannerMessageView(message: String, buttonTitle: String) -> some View {
        ZStack {
            BannerSkeletonView()
            VStack(spacing: 12) {
                ErrorMessageView(message: message, height: nil)
                Button(buttonTitle) {
                    viewModel.retry()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(ThemeColor.sakura)
                .clipShape(Capsule())
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
