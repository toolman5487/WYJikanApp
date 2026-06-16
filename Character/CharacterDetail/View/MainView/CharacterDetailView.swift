//
//  CharacterDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailView: View {
    let malId: Int

    var body: some View {
        CharacterDetailConfiguredView(malId: malId)
    }
}

private struct CharacterDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int

    var body: some View {
        CharacterDetailBodyView(malId: malId, dependencies: dependencies)
    }
}

private struct CharacterDetailBodyView: View {

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: CharacterDetailViewModel
    @State private var isShowingAnimeRoleList = false
    @State private var isShowingMangaRoleList = false
    @State private var isShowingVoiceActorList = false

    // MARK: - Lifecycle

    init(malId: Int, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: dependencies.makeCharacterDetailViewModel(malId: malId))
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
            case .error(let failure):
                ErrorMessageView(state: ErrorMessageView.State(failure: failure), height: 200)
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
        .navigationDestination(isPresented: $isShowingAnimeRoleList) {
            if let character = currentCharacter {
                CharacterDetailAnimeRolesListView(
                    characterName: viewModel.displayName(for: character),
                    roles: viewModel.animeRoles(for: character),
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingMangaRoleList) {
            if let character = currentCharacter {
                CharacterDetailMangaRolesListView(
                    characterName: viewModel.displayName(for: character),
                    roles: viewModel.mangaRoles(for: character),
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingVoiceActorList) {
            if let character = currentCharacter {
                CharacterDetailVoiceActorsListView(
                    characterName: viewModel.displayName(for: character),
                    voices: viewModel.voiceActors(for: character),
                    viewModel: viewModel
                )
            }
        }
        .toolbar {
            DetailExternalActionsToolbar(
                shareState: viewModel.shareNavigationState(),
                externalPageState: viewModel.externalPageNavigationState()
            )
        }
        .task(id: malId, priority: .userInitiated) {
            await viewModel.load()
        }
    }

    // MARK: - Private Methods

    private var currentCharacter: CharacterDetailDTO? {
        if case .loaded(let character) = viewModel.screenState {
            return character
        }
        return nil
    }

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
        let characterName = viewModel.displayName(for: character)

        switch section {
        case .header:
            CharacterDetailHeaderSectionView(viewModel: viewModel, character: character)
        case .info:
            CharacterDetailInfoSectionView(viewModel: viewModel, character: character)
        case .about:
            CharacterDetailAboutSectionView(viewModel: viewModel, character: character)
        case .anime:
            CharacterDetailAnimeWorksSectionView(
                viewModel: viewModel,
                character: character,
                characterName: characterName,
                isShowingAnimeRoleList: $isShowingAnimeRoleList
            )
        case .manga:
            CharacterDetailMangaWorksSectionView(
                viewModel: viewModel,
                character: character,
                characterName: characterName,
                isShowingMangaRoleList: $isShowingMangaRoleList
            )
        case .voices:
            CharacterDetailVoiceActorsSectionView(
                viewModel: viewModel,
                character: character,
                characterName: characterName,
                isShowingVoiceActorList: $isShowingVoiceActorList
            )
        }
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView(malId: 1)
    }
}
