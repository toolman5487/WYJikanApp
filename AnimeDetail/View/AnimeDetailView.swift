//
//  AnimeDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailView: View {
    enum Section: Identifiable {
        case header
        case highlights
        case basicInfo
        case score
        case synopsis
        case staff

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .basicInfo: return "basicInfo"
            case .score: return "score"
            case .synopsis: return "synopsis"
            case .staff: return "staff"
            }
        }
    }

    let malId: Int

    @StateObject private var viewModel: AnimeDetailViewModel

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(malId: malId, service: service))
    }

    var body: some View {
        Group {
            if let anime = viewModel.detail {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: anime)) { section in
                            sectionView(section, viewModel: viewModel, anime: anime)
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
                        AnimeDetailHeaderSectionSkeletonView()
                        AnimeDetailHighlightsSectionSkeletonView()
                        AnimeDetailBasicInfoSectionSkeletonView()
                        AnimeDetailScoreSectionSkeletonView()
                        AnimeDetailSynopsisSectionSkeletonView()
                        AnimeDetailStaffSectionSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.load()
        }
    }

    // MARK: - Sections

    private func sections(for anime: AnimeDetailDTO) -> [Section] {
        var result: [Section] = [
            .header,
            .highlights,
            .basicInfo,
            .score
        ]
        if viewModel.hasSynopsis(for: anime) {
            result.append(.synopsis)
        }
        if viewModel.hasStaffInfo(for: anime) {
            result.append(.staff)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, viewModel: AnimeDetailViewModel, anime: AnimeDetailDTO) -> some View {
        switch section {
        case .header:
            AnimeDetailHeaderSectionView(viewModel: viewModel, anime: anime)
        case .highlights:
            AnimeDetailHighlightsSectionView(viewModel: viewModel, anime: anime)
        case .basicInfo:
            AnimeDetailBasicInfoSectionView(viewModel: viewModel, anime: anime)
        case .score:
            AnimeDetailScoreSectionView(viewModel: viewModel, anime: anime)
        case .synopsis:
            AnimeDetailSynopsisSectionView(anime: anime)
        case .staff:
            AnimeDetailStaffSectionView(viewModel: viewModel, anime: anime)
        }
    }
}

#Preview {
    NavigationStack {
        AnimeDetailView(malId: 52991)
    }
}
