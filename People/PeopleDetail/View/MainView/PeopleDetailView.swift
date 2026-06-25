//
//  PeopleDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailView: View {
    let malId: Int

    var body: some View {
        PeopleDetailConfiguredView(malId: malId)
    }
}

private struct PeopleDetailConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.requestParentTab) private var requestParentTab
    let malId: Int

    var body: some View {
        PeopleDetailBodyView(
            malId: malId,
            parentTab: requestParentTab,
            dependencies: dependencies
        )
    }
}

private struct PeopleDetailBodyView: View {

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: PeopleDetailViewModel
    @State private var isShowingVoiceRoleList = false
    @State private var isShowingAnimeStaffList = false
    @State private var isShowingMangaStaffList = false

    // MARK: - Lifecycle

    init(malId: Int, parentTab: JikanAPIRequestScope, dependencies: AppDependencies) {
        self.malId = malId
        _viewModel = StateObject(
            wrappedValue: dependencies.makePeopleDetailViewModel(
                malId: malId,
                parentTab: parentTab
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loaded(let person):
                detailScroll {
                    ForEach(viewModel.sections(for: person)) { section in
                        sectionView(section, person: person)
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
        .navigationDestination(isPresented: $isShowingVoiceRoleList) {
            if let person = currentPerson {
                PeopleDetailVoiceRolesListView(
                    personName: viewModel.displayName(for: person),
                    roles: viewModel.voiceRolesWithCharacter(for: person),
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingAnimeStaffList) {
            if let person = currentPerson {
                PeopleDetailAnimeStaffListView(
                    personName: viewModel.displayName(for: person),
                    positions: viewModel.animeStaffPositions(for: person),
                    viewModel: viewModel
                )
            }
        }
        .navigationDestination(isPresented: $isShowingMangaStaffList) {
            if let person = currentPerson {
                PeopleDetailMangaStaffListView(
                    personName: viewModel.displayName(for: person),
                    positions: viewModel.mangaStaffPositions(for: person),
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
        .requestScreenTabLifecycle(viewModel: viewModel)
    }

    // MARK: - Private Methods

    private var currentPerson: PeopleDetailDTO? {
        if case .loaded(let person) = viewModel.screenState {
            return person
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
    private func sectionView(_ section: PeopleDetailViewModel.Section, person: PeopleDetailDTO) -> some View {
        switch section {
        case .header:
            PeopleDetailHeaderSectionView(viewModel: viewModel, person: person)
        case .info:
            PeopleDetailInfoSectionView(viewModel: viewModel, person: person)
        case .about:
            PeopleDetailAboutSectionView(viewModel: viewModel, person: person)
        case .voices:
            PeopleDetailVoiceRolesSectionView(
                viewModel: viewModel,
                person: person,
                personName: viewModel.displayName(for: person),
                isShowingVoiceRoleList: $isShowingVoiceRoleList
            )
        case .anime:
            PeopleDetailAnimeStaffSectionView(
                viewModel: viewModel,
                person: person,
                personName: viewModel.displayName(for: person),
                isShowingAnimeStaffList: $isShowingAnimeStaffList
            )
        case .manga:
            PeopleDetailMangaStaffSectionView(
                viewModel: viewModel,
                person: person,
                personName: viewModel.displayName(for: person),
                isShowingMangaStaffList: $isShowingMangaStaffList
            )
        }
    }
}

#Preview {
    NavigationStack {
        PeopleDetailView(malId: 1)
    }
}
