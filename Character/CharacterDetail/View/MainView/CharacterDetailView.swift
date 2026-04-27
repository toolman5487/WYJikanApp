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

    enum Section: Identifiable {
        case header
        case info
        case about
        case anime
        case manga
        case voices

        var id: String {
            switch self {
            case .header: return "header"
            case .info: return "info"
            case .about: return "about"
            case .anime: return "anime"
            case .manga: return "manga"
            case .voices: return "voices"
            }
        }
    }

    private func sections(for character: CharacterDetailDTO) -> [Section] {
        var result: [Section] = [.header, .info]
        if viewModel.aboutText(for: character) != nil {
            result.append(.about)
        }
        if !viewModel.animeRoles(for: character).isEmpty {
            result.append(.anime)
        }
        if !viewModel.mangaRoles(for: character).isEmpty {
            result.append(.manga)
        }
        if !viewModel.voiceActors(for: character).isEmpty {
            result.append(.voices)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, character: CharacterDetailDTO) -> some View {
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
            switch viewModel.viewState {
            case .loaded(let character):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: character)) { section in
                            sectionView(section, character: character)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .error(let message):
                ErrorMessageView(message: message, height: 200)
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
            ToolbarItem(placement: .topBarTrailing) {
                if let detail = viewModel.detail, let url = viewModel.malPageURL(for: detail) {
                    NavigationLink {
                        NavigationWebPageView(title: viewModel.displayName(for: detail), url: url)
                    } label: {
                        Image(systemName: "safari")
                            .font(.body.weight(.bold))
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
        CharacterDetailView(malId: 1)
    }
}
