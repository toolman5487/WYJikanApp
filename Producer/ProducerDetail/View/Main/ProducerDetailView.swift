//
//  ProducerDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/22.
//

import SwiftUI

struct ProducerDetailView: View {
    let malId: Int

    var body: some View {
        ProducerDetailConfiguredView(malId: malId)
    }
}

private struct ProducerDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int

    var body: some View {
        ProducerDetailBodyView(malId: malId, dependencies: dependencies)
    }
}

private struct ProducerDetailBodyView: View {

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: ProducerDetailViewModel

    // MARK: - Lifecycle

    init(malId: Int, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(
            wrappedValue: dependencies.makeProducerDetailViewModel(malId: malId)
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loaded(let producer):
                detailScroll {
                    ForEach(viewModel.sections(for: producer)) { section in
                        sectionView(section, producer: producer)
                    }
                }
            case .error(let failure):
                ProducerDetailErrorView(
                    failure: failure,
                    onRetry: retry
                )
                .padding()
            case .loading:
                detailScroll {
                    ProducerDetailHeaderSkeletonView()
                    ProducerDetailInfoSkeletonView()
                    ProducerDetailAboutSkeletonView()
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailExternalActionsToolbar(
                shareState: viewModel.shareNavigationState(),
                externalPageState: viewModel.externalPageNavigationState()
            )
        }
        .task(id: malId, priority: .userInitiated) {
            await viewModel.screenDidAppear()
        }
        .onDisappear {
            viewModel.screenDidDisappear()
        }
    }

    // MARK: - Private Methods

    private var navigationTitle: String {
        viewModel.detail.map(viewModel.displayName) ?? "製作公司"
    }

    private func detailScroll<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func sectionView(
        _ section: ProducerDetailViewModel.Section,
        producer: ProducerDetailDTO
    ) -> some View {
        switch section {
        case .header:
            ProducerDetailHeaderSectionView(
                viewModel: viewModel,
                producer: producer
            )
        case .info:
            ProducerDetailInfoSectionView(
                viewModel: viewModel,
                producer: producer
            )
        case .about:
            ProducerDetailAboutSectionView(
                viewModel: viewModel,
                producer: producer
            )
        case .links:
            ProducerDetailExternalLinksSectionView(
                viewModel: viewModel,
                producer: producer
            )
        case .anime:
            ProducerRelatedAnimeSectionView(
                state: viewModel.relatedAnimeState,
                producerId: producer.malId,
                producerName: viewModel.displayName(for: producer),
                onRetry: retryRelatedAnime
            )
        }
    }

    private func retry() {
        Task(priority: .userInitiated) {
            await viewModel.reload()
        }
    }

    private func retryRelatedAnime() {
        Task(priority: .userInitiated) {
            await viewModel.retryRelatedAnime()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProducerDetailView(malId: 1)
    }
}
