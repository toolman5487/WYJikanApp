//
//  CharacterDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailView: View {
    let malId: Int

    @StateObject private var viewModel: CharacterDetailViewModel

    init(malId: Int, service: CharacterDetailServicing = CharacterDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: CharacterDetailViewModel(malId: malId, service: service))
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

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loaded(let character):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.sections(for: character)) { section in
                            sectionView(section, character: character)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .error(let message):
                ErrorMessageView(state: .network(message), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        CharacterDetailHeaderSectionSkeletonView()
                        CharacterDetailInfoSectionSkeletonView()
                        CharacterDetailAboutSectionSkeletonView()
                        CharacterDetailHorizontalCardsSkeletonView()
                        CharacterDetailHorizontalCardsSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
    NavigationStack {
        CharacterDetailView(malId: 1)
    }
}
