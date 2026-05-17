//
//  PeopleDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailView: View {
    let malId: Int

    @StateObject private var viewModel: PeopleDetailViewModel

    init(malId: Int, service: PeopleDetailServicing = PeopleDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: PeopleDetailViewModel(malId: malId, service: service))
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
            PeopleDetailVoiceRolesSectionView(viewModel: viewModel, person: person)
        case .anime:
            PeopleDetailAnimeStaffSectionView(viewModel: viewModel, person: person)
        case .manga:
            PeopleDetailMangaStaffSectionView(viewModel: viewModel, person: person)
        }
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loaded(let person):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.sections(for: person)) { section in
                            sectionView(section, person: person)
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
        PeopleDetailView(malId: 1)
    }
}
