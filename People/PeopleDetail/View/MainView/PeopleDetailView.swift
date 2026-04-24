//
//  PeopleDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Combine
import Foundation
import SwiftUI

struct PeopleDetailView: View {

    let malId: Int

    @StateObject private var viewModel: PeopleDetailViewModel

    init(malId: Int, service: PeopleDetailServicing = PeopleDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: PeopleDetailViewModel(malId: malId, service: service))
    }

    enum Section: Identifiable {
        case header
        case info
        case about
        case voices
        case anime
        case manga

        var id: String {
            switch self {
            case .header: return "header"
            case .info: return "info"
            case .about: return "about"
            case .voices: return "voices"
            case .anime: return "anime"
            case .manga: return "manga"
            }
        }
    }

    private func sections(for person: PeopleDetailDTO) -> [Section] {
        var result: [Section] = [.header, .info]
        if viewModel.aboutText(for: person) != nil {
            result.append(.about)
        }
        if !viewModel.voiceRoles(for: person).isEmpty {
            result.append(.voices)
        }
        if !viewModel.animeStaffPositions(for: person).isEmpty {
            result.append(.anime)
        }
        if !viewModel.mangaStaffPositions(for: person).isEmpty {
            result.append(.manga)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, person: PeopleDetailDTO) -> some View {
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
            if let person = viewModel.detail {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: person)) { section in
                            sectionView(section, person: person)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let message = viewModel.errorMessage {
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
            ToolbarItem(placement: .topBarTrailing) {
                if let detail = viewModel.detail, let url = viewModel.malPageURL(for: detail) {
                    NavigationLink {
                        NavigationWebPageView(title: viewModel.displayName(for: detail), url: url)
                    } label: {
                        Image(systemName: "safari")
                            .font(.body)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
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
