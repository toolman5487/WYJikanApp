//
//  CharacterDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailView: View {

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: CharacterDetailViewModel

    // MARK: - Lifecycle

    init(malId: Int, service: CharacterDetailServicing = CharacterDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: CharacterDetailViewModel(malId: malId, service: service))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loaded(let character):
                detailScroll {
                    ForEach(viewModel.sections(for: character)) { section in
                        sectionView(section, character: character)
                    }
                }
            case .error(let message):
                ErrorMessageView(state: .network(message), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                detailScroll {
                    CharacterDetailHeaderSectionSkeletonView()
                    CharacterDetailInfoSectionSkeletonView()
                    CharacterDetailAboutSectionSkeletonView()
                    CharacterDetailHorizontalCardsSkeletonView()
                    CharacterDetailHorizontalCardsSkeletonView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailExternalActionsToolbar(
                shareState: viewModel.shareNavigationState(),
                externalPageState: viewModel.externalPageNavigationState()
            )
        }
        .task(id: malId) {
            await viewModel.load()
        }
    }

    // MARK: - Private Methods

    private func detailScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                content()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: CharacterDetailViewModel.Section, character: CharacterDetailDTO) -> some View {
        switch section {
        case .header:
            CharacterDetailHeaderSectionView(viewModel: viewModel, character: character)
        case .info:
            CharacterDetailInfoSectionView(viewModel: viewModel, character: character)
        case .about:
            CharacterDetailAboutSectionView(viewModel: viewModel, character: character)
        case .anime:
            CharacterDetailAnimeWorksSectionView(viewModel: viewModel, character: character)
        case .manga:
            CharacterDetailMangaWorksSectionView(viewModel: viewModel, character: character)
        case .voices:
            CharacterDetailVoiceActorsSectionView(viewModel: viewModel, character: character)
        }
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView(malId: 1)
    }
}
