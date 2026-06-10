//
//  PeopleDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailView: View {

    // MARK: - Properties

    let malId: Int
    @StateObject private var viewModel: PeopleDetailViewModel

    // MARK: - Lifecycle

    init(malId: Int, service: PeopleDetailServicing = PeopleDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: PeopleDetailViewModel(malId: malId, service: service))
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
}

#Preview {
    NavigationStack {
        PeopleDetailView(malId: 1)
    }
}
